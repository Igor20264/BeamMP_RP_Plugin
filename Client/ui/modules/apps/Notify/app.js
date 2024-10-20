var app = angular.module('beamng.apps');


app.directive('roleplaynot', [function () {
	return {
		templateUrl: '/ui/modules/apps/Notify/app.html',
		replace: true,
		restrict: 'EA',
		scope: true,
		controllerAs: 'ctrl'	
	}
}]);

app.controller("NotifyInit", ['$scope', '$timeout', function ($scope, $timeout) {
    $scope.notifications = [];

    $scope.init = function() {
        // bngApi.engineLua('RolePlaySub.Sendpacket()');
    };

    $scope.reset = function() {
        $scope.init();
    };

    $scope.select = function() {
        bngApi.engineLua('setCEFFocus(true)');
    };

	$scope.showNotification = function(type, title, text, duration) {
        var width = (type === 'green' ? 65 : (type === 'yellow' ? 60 : 50)); // Example logic for width based on type
        var notification = {
            type: type,
            title: title,
            text: text,
            width: width,
            visible: true
        };
        
        $scope.notifications.push(notification);

        $timeout(function() {
            notification.visible = false;
        }, duration || 10000); // Notification disappears after 3 seconds by default
    };

    $scope.$on('setNotify', function (event, color, title, text) {
		$scope.showNotification( color, title, text, 5000);
	});

    // Example call for testing
}]);
