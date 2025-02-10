var app = angular.module('beamng.apps');

app.directive('steamAchievement', [function () {
    return {
        templateUrl: '/ui/modules/apps/Omb_Achievement/app.html',
        replace: true,
        restrict: 'EA',
        scope: true,
        controllerAs: 'ctrl'
    };
}]);

app.controller("AchievementCtrl", ['$scope', '$timeout', function ($scope, $timeout) {
    $scope.achievementTitle = "";
    $scope.achievementDescription = "";
    $scope.achievementImage = "/ui/modules/apps/Omb_Achievement/images/default_icon.png"; // Дефолтная иконка
    let timeoutPromise;

    $scope.showAchievement = function(title, desc, img) {
        // Очищаем предыдущий таймер, если он существует
        if (timeoutPromise) {
            $timeout.cancel(timeoutPromise);
        }

        // Обновляем данные достижения
        $scope.achievementTitle = title || "Без названия";
        $scope.achievementDescription = desc || "Описание недоступно";
        $scope.achievementImage = img || "/ui/modules/apps/Omb_Achievement/images/default_icon.png";

        // Показываем контейнер
        const element = document.querySelector('.achievement-container');
        element.classList.add('visible');

        // Автоматическое скрытие через 5 секунд
        timeoutPromise = $timeout(() => {
            element.classList.remove('visible');
        }, 5000);
    };

    // Слушаем событие для отображения достижения
    $scope.$on('triggerAchievement', function (event, data) {
        $scope.showAchievement(data.title, data.desc, data.img);
    });

    // Очищаем таймер при уничтожении контроллера
    $scope.$on('$destroy', function() {
        if (timeoutPromise) {
            $timeout.cancel(timeoutPromise);
        }
    });
}]);