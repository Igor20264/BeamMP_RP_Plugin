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

    $scope.showNotification = function(type, title, text, duration) {
    var width = (type === 'green' ? 65 : (type === 'yellow' ? 60 : 50));
    var notification = {
        type: type,
        title: title,
        text: text,
        width: width,
        visible: true
    };

    $scope.notifications.push(notification);

    // Устанавливаем ширину цветной полосы на 100% после добавления уведомления
    $timeout(function() {
        notification.loadingWidth = '100%'; // Устанавливаем ширину на 100%
    }, 0); // Задержка 0, чтобы дождаться следующего цикла отрисовки

    // Устанавливаем таймер для исчезновения уведомления
    $timeout(function() {
        notification.visible = false;
    }, duration || 5000);
};

}]);

