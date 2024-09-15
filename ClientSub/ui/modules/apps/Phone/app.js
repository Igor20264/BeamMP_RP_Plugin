var app = angular.module('beamng.apps');

app.directive('roleplayphone', [function () {
    return {
        templateUrl: '/ui/modules/apps/Phone/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    }
}]);

app.controller("PhoneInit", ['$scope', '$window', function ($scope, $window) {
    $scope.init = function() {bngApi.engineLua('RolePlaySub.packetPhoneUpdate()');};
    $scope.select = function() {bngApi.engineLua('setCEFFocus(true)');};
}]);

document.addEventListener('DOMContentLoaded', function() {
	console.log("phone_loaded")
    var openButton = document.querySelector('.open_phone');
    var closeButton = document.querySelector('.close_phone');
    var image = document.querySelector('.phone .phone-image');

    if (openButton && closeButton && image) {
        openButton.addEventListener('click', function() {
            image.classList.add('visible');
            openButton.style.display = 'none';
            closeButton.style.display = 'block';
        });

        closeButton.addEventListener('click', function() {
            image.classList.remove('visible');
            openButton.style.display = 'block';
            closeButton.style.display = 'none';
        });
    } else {
        console.error('One or more elements not found:', { openButton, closeButton, image });
    }
});
