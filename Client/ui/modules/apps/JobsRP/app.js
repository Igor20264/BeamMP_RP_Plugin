var app = angular.module('beamng.apps');


app.directive('roleplayjobs', [function () {
	return {
		templateUrl: '/ui/modules/apps/JobsRP/app.html',
		replace: true,
		restrict: 'EA',
		scope: true,
		controllerAs: 'ctrl'
	}
}]);
	
app.controller("JobsInit", ['$scope', function ($scope) {
	$scope.init = function() {bngApi.engineLua('RolePlaySub.packetJobsUpdate()');};
	$scope.reset = function() {$scope.init();};
	$scope.select = function() {bngApi.engineLua('setCEFFocus(true)');};

	$scope.$on('setRP-Jobs-name', function (event, BalanceUser) {
		document.getElementById("RP-Jobs-name").innerHTML = BalanceUser;
	});

	$scope.startwork = function() {
		bngApi.engineLua('RolePlaySub.startworkbutton()');
	};

	$scope.$on('setRP-Jobs-name', function (event, JobNameUser) {
		document.getElementById("RP-Jobs-name").innerHTML = JobNameUser;
	});

	$scope.$on('setRP-Jobs-button-name', function (event, ButtonName) {
		document.getElementById("RP-Jobs-button-name").innerHTML = ButtonName;
	});


}]);
