var app = angular.module('beamng.apps');

app.directive('ombAchi', [function () {
    return {
        //template: '<div>Test Directive</div>', // Временный тестовый шаблон
        templateUrl: '/ui/modules/apps/ombAchi/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller("ombAchiInit", ['$scope', '$timeout', function ($scope, $timeout) {
    $scope.achievements = [];
    
    $scope.init = function () {
        bngApi.engineLua('log("ombAchi: init")');
    };

    $scope.reset = function() {
        $scope.init();
    };

    $scope.showAchievement = function (title, desc, image) {
        var achievement = {
            title: title,
            desc: desc,
            image: image || "/ui/images/beamng_logo_50x50.png",
            visible: true
        };
        $scope.achievements.push(achievement);

        if ($scope.achievements.length > 5) {
            $scope.achievements.shift();
        }

        $timeout(function () {
            achievement.show = true;
        }, 0);

        $timeout(function () {
            achievement.visible = false;
            delete achievement.show;
        }, 5000);
    };

    $scope.$on('triggerAchievement', function (event, data) {
        $scope.showAchievement(data.title, data.desc, data.image);
    });
}]);