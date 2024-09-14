var app = angular.module('beamng.apps');

app.directive('multiplayerpogonizaderzhanie', [function () {
	return {
		templateUrl: '/ui/modules/apps/PogoniZaderzhanie/app.html',
		replace: false,
		restrict: 'EA',
		scope: false,
		controllerAs: 'ctrl'
	}
}]);

app.controller("PogoniZaderzhanie", ['$scope', function ($scope) {
	$scope.init = function() {bngApi.engineLua('PogoniVa582.ObnovitjInterfejsPoUmolchaniju()');};
	$scope.reset = function() {$scope.init();};
	
	$scope.$on('ustanovitPolosaZaderzhanija', function (event, PolosaZaderzhanija) {
		if (PolosaZaderzhanija.Podozrevaemyj1Zaderzhanie != 0) {
			document.getElementById("BlokZaderzhanie1").style.display = "flex";
			document.getElementById("BlokZaderzhanie1Zapolnenie").style.width = String(PolosaZaderzhanija.Podozrevaemyj1Zaderzhanie) + "%";
			document.getElementById("BlokZaderzhanie1Tekst").innerHTML = PolosaZaderzhanija.Podozrevaemyj1;
		} else {
			document.getElementById("BlokZaderzhanie1").style.display = "none";
			document.getElementById("BlokZaderzhanie1Zapolnenie").style.width = "0";
			document.getElementById("BlokZaderzhanie1Tekst").innerHTML = "";
		}
		if (PolosaZaderzhanija.Podozrevaemyj2Zaderzhanie != 0) {
			document.getElementById("BlokZaderzhanie2").style.display = "flex";
			document.getElementById("BlokZaderzhanie2Zapolnenie").style.width = String(PolosaZaderzhanija.Podozrevaemyj2Zaderzhanie) + "%";
			document.getElementById("BlokZaderzhanie2Tekst").innerHTML = PolosaZaderzhanija.Podozrevaemyj2;
		} else {
			document.getElementById("BlokZaderzhanie2").style.display = "none";
			document.getElementById("BlokZaderzhanie2Zapolnenie").style.width = "0";
			document.getElementById("BlokZaderzhanie2Tekst").innerHTML = "";
		}
	});
	
}]);