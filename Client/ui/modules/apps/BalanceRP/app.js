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

app.controller("BalanceInit", ['$scope', function ($scope) {
	$scope.init = function() {bngApi.engineLua('RolePlaySub.balanceUpdate()');};
	$scope.reset = function() {$scope.init();};
	$scope.select = function() {bngApi.engineLua('setCEFFocus(true)');};

	$scope.$on('setRP-Balance', function (event, BalanceUser) {
		document.getElementById("RP-Balance").innerHTML = BalanceUser;
	});


}]);
