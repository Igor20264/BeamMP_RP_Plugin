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
        var notification = {
            type: type,
            title: title,
            text: text,
            width: 0,
            visible: true
        };

        $scope.notifications.push(notification);

        // Удаление старых уведомлений, если их больше 5
        if ($scope.notifications.length > 5) {
            $scope.notifications.shift(); // Удаляет первое уведомление
        }

        $timeout(function() {
            notification.width = 100; // Set width to 100 after a short delay
        }, 1500); // Delay to allow the DOM to update

    };

    $scope.$on('setNotify', function (event, color, title, text, duration) {
        $scope.showNotification(color, title, text, duration);
    });

    // Example call for testing
}]);