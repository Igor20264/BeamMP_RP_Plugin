angular.module('beamng.apps')
  .directive('winds', [function () {
    return {
      template:
        '<div class="bngApp">' +
        '<object style="width:100%;" type="image/svg+xml" data="/ui/modules/apps/Winds/winds.svg"></object>' +
        '<md-slider flex min=0 max=210 ng-model="wind.mag" aria-label="_" style="padding: 0 10px"></md-slider>' +
        '</div>',

      replace: true,

      controller: ['$scope', function ($scope) {
        $scope.wind = {
        }


        // fix this:
        // bngApi.systemLua('objectBroadcast"obj:getWindSpeed()"', function (val) {
        //   $scope.$evalAsync(function () {
        //     $scope.wind.mag = val
        //   })
        // })

        $scope.$watch('wind', function (newVal, oldVal) {
        }, true)
      }],

      link: function (scope, element, attrs) {
        var streamsList = ['sensors']
        StreamsManager.add(streamsList)
        scope.$on('$destroy', function () {
          StreamsManager.remove(streamsList)
        })

        var obj = angular.element(element[0].children[0])

        obj.on('load', function () {
        })
      }
    }
  }]);
