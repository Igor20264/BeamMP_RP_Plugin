angular.module('beamng.apps')
.directive('CnRUI', ['StreamsManager', function (StreamsManager) {
  return {
    template:  '<button ng-click="rob()">Click Me</button>',
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
    
    const uiData = {CnRBalance:0, performanceLevel:0,repairCost:0}
    scope.$on('updatePlayerUI', function (event,data){
    uiData = data
    scope.$apply();
    
    scope.rob = function() {
      bngApi.engineLua('extensions.cnr.rob()')
    };
    
    
     
    }
      };
    }
  };
}])
