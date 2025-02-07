// achievement.js
var app = angular.module('beamng.apps');

app.directive('steamAchievement', [function () {
	return {
		templateUrl: '/ui/modules/apps/Achievement/achievement.html',
		replace: true,
		restrict: 'EA',
		scope: true,
		controllerAs: 'ctrl'
	}
}]);

app.controller("AchievementCtrl", ['$scope', '$timeout', function ($scope, $timeout) {
    $scope.achievementTitle = "";
    $scope.achievementDescription = "";
    $scope.achievementImage = "";

    let timeoutPromise;

    $scope.showAchievement = function(title, desc, img) {
        $scope.achievementTitle = title;
        $scope.achievementDescription = desc;
        $scope.achievementImage = img || "/ui/modules/apps/Achievement/images/default_icon.png"; // Дефолтная иконка

        const element = document.querySelector('.achievement-container');
        element.classList.add('visible');

        // Автоматическое скрытие через 5 секунд
        timeoutPromise = $timeout(() => {
            element.classList.remove('visible');
        }, 5000);
    };

    $scope.$on('triggerAchievement', function (event, data) {
        $scope.showAchievement(data.title, data.desc, data.img);
    });

    $scope.$on('$destroy', function() {
        $timeout.cancel(timeoutPromise);
    });
}]);