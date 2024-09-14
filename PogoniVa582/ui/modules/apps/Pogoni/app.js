var app = angular.module('beamng.apps');

var VyborKomandViden = false;
var VyborPogoniViden = false;

app.directive('multiplayerpogoni', [function () {
	return {
		templateUrl: '/ui/modules/apps/Pogoni/app.html',
		replace: true,
		restrict: 'EA',
		scope: true,
		controllerAs: 'ctrl'
	}
}]);

app.controller("Pogoni", ['$scope', function ($scope) {
	$scope.init = function() {bngApi.engineLua('PogoniVa582.ObnovitjInterfejsPoUmolchaniju()');};
	$scope.reset = function() {$scope.init();};
	$scope.select = function() {bngApi.engineLua('setCEFFocus(true)');};
	
	$scope.StatGrazhdanskim = function() {bngApi.engineLua("PogoniVa582.ZaprosSmenyKomandy('Civil')");};
	$scope.StatPolicejskim = function() {bngApi.engineLua("PogoniVa582.ZaprosSmenyKomandy('Police')");};
	$scope.StatPodozrevaemym = function() {bngApi.engineLua("PogoniVa582.ZaprosSmenyKomandy('Suspect')");};
	$scope.Klassicheskaja10min = function() {bngApi.engineLua("PogoniVa582.ZaprosZapuskaPogoni('1')");};
	$scope.Klassicheskaja15min = function() {bngApi.engineLua("PogoniVa582.ZaprosZapuskaPogoni('2')");};
	$scope.PoKontroljnymTochkam6tochek = function() {bngApi.engineLua("PogoniVa582.ZaprosZapuskaPogoni('3')");};
	$scope.UstanovitjTochkuRemonta = function() {bngApi.engineLua("PogoniVa582.PodgotovkaZaprosUstanovitjTochkuRemonta()")};
	$scope.Gotovnostj = function() {bngApi.engineLua("PogoniVa582.PodgotovkaZaprosGotovnostj()")};
	$scope.ZaprositRemont = function() {bngApi.engineLua("PogoniVa582.PogonjaZaprosRemont()")};
	$scope.VyjtiIzPogoni = function() {bngApi.engineLua("PogoniVa582.PogonjaZaprosVyjti()")};
	$scope.NachatjRemont = function() {bngApi.engineLua("PogoniVa582.PogonjaZaprosNachatjRemont()")};
	$scope.PrervatjRemont = function() {bngApi.engineLua("PogoniVa582.PogonjaZaprosPrervatjRemont()")};
	$scope.OtkatNaSpavn = function() {bngApi.engineLua("PogoniVa582.PogonjaZaprosOtkatNaSpavn()")};
	
	$scope.$on('ustanovitStatus', function (event, Status) {
		document.getElementById("Pogonya-Status").innerHTML = Status.StatusStrokoj;
	});
	
	$scope.$on('ustanovitKomandyIgrokov', function (event, KomandyIgrokov) {
		document.getElementById("Pogonya-Imja").innerHTML = KomandyIgrokov.ImjaIgroka;
		document.getElementById("Pogonya-Komanda").innerHTML = "&nbsp;" + KomandyIgrokov.KomandaIgroka + "&nbsp;";
		if (KomandyIgrokov.KomandaIgroka == "гражданский") {
			document.getElementById("Pogonya-Komanda").style.background = "rgba(63, 63, 63, 0.25)";
		} else if (KomandyIgrokov.KomandaIgroka == "полицейский") {
			document.getElementById("Pogonya-Komanda").style.background = "rgba(31, 31, 127, 0.25)";
		} else if (KomandyIgrokov.KomandaIgroka == "подозреваемый") {
			document.getElementById("Pogonya-Komanda").style.background = "rgba(127, 31, 31, 0.25)";
		} else {
			document.getElementById("Pogonya-Komanda").style.background = "rgba(127, 127, 127, 0.25)";
		}
		document.getElementById("Pogonya-Grazhdanskih").innerHTML = "&nbsp;" + KomandyIgrokov.Grazhdanskih + "&nbsp;";
		document.getElementById("Pogonya-Policeiskih").innerHTML = "&nbsp;" + KomandyIgrokov.Policeiskih + "&nbsp;";
		document.getElementById("Pogonya-Podozrevaemyh").innerHTML = "&nbsp;" + KomandyIgrokov.Podozrevaemyh + "&nbsp;";
		document.getElementById("Pogonya-Policeiskie").innerHTML = KomandyIgrokov.PoliceiskieStrokoj;
		document.getElementById("Pogonya-Podozrevaemye").innerHTML = KomandyIgrokov.PodozrevaemyeStrokoj;
	});
	
	$scope.$on('ustanovitOzhidanie', function (event, SmenaKomand) {
		if (SmenaKomand.Vidno == true) {
			document.getElementById("BlokiStrokaOzhidanie").style.display = "flex";
		} else {
			document.getElementById("BlokiStrokaOzhidanie").style.display = "none";
		}
	});
	
	$scope.$on('ustanovitSmenaKomand', function (event, SmenaKomand) {
		if (SmenaKomand.Vidno == true) {
			document.getElementById("BlokiStrokaSmenaKomandy").style.display = "flex";
		} else {
			document.getElementById("BlokiStrokaSmenaKomandy").style.display = "none";
		}
	});
	
	$scope.$on('ustanovitGolosovanie', function (event, Golosovanie) {
		if (Golosovanie.Vidno == true) {
			document.getElementById("BlokiStrokaGolosovanie").style.display = "flex";
		} else {
			document.getElementById("BlokiStrokaGolosovanie").style.display = "none";
		}
		document.getElementById("GolosovanieVremja").innerHTML = Golosovanie.Vremja;
	});
	
	$scope.$on('ustanovitPodgotovka', function (event, Podgotovka) {
		if (Podgotovka.Vidno == true) {
			document.getElementById("BlokiStrokaPodgotovka").style.display = "flex";
			document.getElementById("BlokiStrokaPodgotovka2").style.display = "flex";
			document.getElementById("BlokiStrokaPodgotovka3").style.display = "flex";
		} else {
			document.getElementById("BlokiStrokaPodgotovka").style.display = "none";
			document.getElementById("BlokiStrokaPodgotovka2").style.display = "none";
			document.getElementById("BlokiStrokaPodgotovka3").style.display = "none";
		}
		document.getElementById("PodgotovkaVremja").innerHTML = Podgotovka.Vremja;
		document.getElementById("PodgotovkaStatus").innerHTML = Podgotovka.Tekst;
		document.getElementById("KnopkaGotovnostj").disabled = false;
	});
	
	$scope.$on('ustanovitVremja', function (event, Vremja) {
		if (Vremja.VremjaOstalosVidno == true) {
			document.getElementById("BlokiStrokaVremja").style.display = "flex";
		} else {
			document.getElementById("BlokiStrokaVremja").style.display = "none";
		}
		document.getElementById("Pogonya-VremjaOstalos").innerHTML = Vremja.VremjaOstalos;
		if (Vremja.VremjaDopVidno == true) {
			document.getElementById("BlokVremjaDop").style.display = "inline-block";
		} else {
			document.getElementById("BlokVremjaDop").style.display = "none";
		}
		document.getElementById("Pogonya-VremjaDop").innerHTML = Vremja.VremjaDop;
	});
	
	$scope.$on('ustanovitPogonjaStatus', function (event, PogonjaStatus) {
		if (PogonjaStatus.Vidno == true) {
			document.getElementById("BlokiStrokaPogonjaInfo").style.display = "flex";
		} else {
			document.getElementById("BlokiStrokaPogonjaInfo").style.display = "none";
		}
		document.getElementById("PogonjaInfo").innerHTML = PogonjaStatus.Tekst;
	});
	
	$scope.$on('ustanovitRezuljtaty', function (event, Rezuljtaty) {
		if (Rezuljtaty.Vidno == true) {
			document.getElementById("BlokiStrokaRezuljtaty").style.display = "flex";
		} else {
			document.getElementById("BlokiStrokaRezuljtaty").style.display = "none";
		}
		document.getElementById("RezuljtatyInfo").innerHTML = Rezuljtaty.Tekst;
	});
	
	$scope.$on('ustanovitKnopkiRemonta', function (event, Rezuljtat) {
		if (Rezuljtat == true) {
			document.getElementById("BlokKnopkaNachatjRemont").style.display = "none";
			document.getElementById("BlokKnopkaOtkatNaSpavn").style.display = "none";
			document.getElementById("BlokKnopkaPrervatjRemont").style.display = "flex";
		} else {
			document.getElementById("BlokKnopkaNachatjRemont").style.display = "flex";
			document.getElementById("BlokKnopkaOtkatNaSpavn").style.display = "flex";
			document.getElementById("BlokKnopkaPrervatjRemont").style.display = "none";
		}
	});
	
}]);

function VyborKomand() {
	if (VyborKomandViden) {
		VyborKomandViden = false;
		document.getElementById("BlokKnopkiSmenKomand").style.display = "none";
	} else {
		if (VyborPogoniViden) {
			VyborPogoni();
		}
		VyborKomandViden = true;
		document.getElementById("BlokKnopkiSmenKomand").style.display = "flex";
	}
}

function VyborPogoni() {
	if (VyborPogoniViden) {
		VyborPogoniViden = false;
		document.getElementById("BlokKnopkiVyboraKomand").style.display = "none";
	} else {
		if (VyborKomandViden) {
			VyborKomand();
		}
		VyborPogoniViden = true;
		document.getElementById("BlokKnopkiVyboraKomand").style.display = "flex";
	}
}

function ZaderzhkaGotovnostj() {
	document.getElementById("KnopkaGotovnostj").disabled = true;
}