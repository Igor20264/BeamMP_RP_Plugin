var app = angular.module('beamng.apps');


app.directive('roleplaybal', [function () {
	return {
		templateUrl: '/ui/modules/apps/BalanceRP/app.html',
		replace: true,
		restrict: 'EA',
		scope: true,
		controllerAs: 'ctrl'	
	}
}]);

app.controller("BalanceInit", ['$scope', '$interval', function ($scope, $interval) {
    // Получаем значение из localStorage или устанавливаем 0
    $scope.balanceUser = localStorage.getItem('balanceUser') ? parseFloat(localStorage.getItem('balanceUser')) : 0;

    $scope.init = function() {
        bngApi.engineLua('RolePlaySub.balanceUpdate()');
    };

    $scope.reset = function() {
        $scope.init();
    };

    $scope.select = function() {
        bngApi.engineLua('setCEFFocus(true)');
    };

    $scope.$on('setRP-Balance', function (event, BalanceUser) {
        if (typeof BalanceUser === 'number' && !isNaN(BalanceUser)) {
            $scope.balanceUser = BalanceUser; // Сохраняем значение как число
            localStorage.setItem('balanceUser', BalanceUser); // Сохраняем в localStorage
        } else if (typeof BalanceUser === 'string') {
            var parsedValue = parseFloat(BalanceUser);
            if (!isNaN(parsedValue)) {
                $scope.balanceUser = parsedValue; // Сохраняем преобразованное значение
                localStorage.setItem('balanceUser', parsedValue); // Сохраняем в localStorage
            }
        }
    });

    function updateBalance() {
        document.getElementById("RP-Balance").innerHTML = $scope.balanceUser;
        console.log($scope.balanceUser);
    }

    var intervalPromise = $interval(updateBalance, 1000);

    $scope.$on('$destroy', function() {
        $interval.cancel(intervalPromise);
    });
}]);


