angular.module('beamng.apps')
	// register service
	.factory('VehicleService', function() {
		var vehicleName = "";
		return {
			getVehicleName: function() { 
				return vehicleName; 
			},
			setVehicleName: function(newVehicleName) 	{ 
				vehicleName = newVehicleName.replace(/_/gi," ")
				},
		};
	})
	.directive('distanceDisplay', ['VehicleService', 'Utils', function (VehicleService, Utils) {
		return {
			templateUrl: "/ui/modules/apps/separatedistancecounter/endurance.html",
			replace: true,
			restrict: 'EA',
			require: '^bngApp',
			controller: ['$log', '$scope', function ($log, $scope) {
			  var streamsList = ['stats', 'sensors', 'electrics', 'engineInfo'];
			  StreamsManager.add(streamsList);

			  $scope.$on('$destroy', function () {
				StreamsManager.remove(streamsList);
			  });

			  $scope.ignition = false;
			  
			  $scope.pitch = 0;
			  $scope.roll = 0;
			  $scope.yaw = 0;
			  
			  $scope.kph = 0;
			  $scope.mph = 0;
			  
			  $scope.weight = {
				total: '',
				wheels: { average: '', total: '', count: ''}
			  };
			  
			  $scope.beams = {
				total: '-',
				deformed: { number: '', percentage: ''},
				broken: { number: '', percentage: ''}
			  };
			  
			  $scope.torsionbars = {
				total: '-',
				deformed: { number: '', percentage: ''},
				broken: { number: '', percentage: ''}
			  };

			  $scope.$on('streamsUpdate', function (event, data) {
				$scope.beams.total    = data.stats.beam_count;
				$scope.beams.deformed = { number: data.stats.beams_deformed, percentage: data.stats.beams_deformed/data.stats.beam_count * 100 };
				$scope.beams.broken   = { number: data.stats.beams_broken, percentage: data.stats.beams_broken/data.stats.beam_count * 100 };
				
				$scope.weight.total  = data.stats.total_weight;
				$scope.weight.wheels = {
				  total: data.stats.wheel_weight,
				  count: data.stats.wheel_count,
				  average: data.stats.wheel_weight / data.stats.wheel_count
				};
				$scope.weight.chassis = data.stats.total_weight - data.stats.wheel_weight;
				
				$scope.torsionbars.total = data.stats.torsionbar_count;
				$scope.torsionbars.deformed = { number: data.stats.torsionbars_deformed, percentage: data.stats.torsionbars_deformed/data.stats.torsionbar_count * 100 };
				$scope.torsionbars.broken = { number: data.stats.torsionbars_broken, percentage: data.stats.torsionbars_broken/data.stats.torsionbar_count * 100 };
				
				$scope.ignitionBool = data.electrics.ignition;
				$scope.runningBinary = data.electrics.engineRunning;
				
				$scope.oilTemp = data.electrics.oiltemp;
				$scope.waterTemp = data.electrics.watertemp;
				$scope.oilTemp2 = (data.electrics.oiltemp * 9 / 5) + 32;
				$scope.waterTemp2 = (data.electrics.watertemp * 9 / 5) + 32;
				
				$scope.currentRPM = data.electrics.rpm;
				$scope.idleRPM = data.engineInfo[0];
				$scope.maxRPM = data.engineInfo[1];
				$scope.meterRPM = (100 / data.engineInfo[1]) * data.electrics.rpm;
				document.getElementById('revMeter').style.width = Math.round($scope.meterRPM) + "%";
				
				var rgb = '';

                if($scope.currentRPM < data.engineInfo[0] * 1.25) { //we are at idle, blue
                    rgb = '(158, 214, 241';
                } else if($scope.currentRPM > data.engineInfo[1] * 0.9) { //we are near redline, red
                    rgb = '(241, 158, 158';
                } else { //normal rpm, green
                    rgb = '(186, 241, 158';
                }
				
				document.getElementById('revMeter').style.background = 'rgba' + rgb + ',0.5)';
				
				if (data.electrics.gear == 0) {
				  $scope.currentGear = 'N';
				} else if (data.electrics.gear < 0) {
				  $scope.currentGear = 'R';
				} else {
				  $scope.currentGear = data.electrics.gear;
				}
				
				$scope.pitch = Math.asin(data.sensors.pitch) * (180 / Math.PI);
				$scope.roll = Math.asin(data.sensors.roll) * (180 / Math.PI);
				$scope.yaw = (data.sensors.yaw * 180 / Math.PI + 180);
				
				$scope.kph = Math.round((data.electrics.wheelspeed * 3.6) * 10) / 10;
				$scope.mph = Math.round(($scope.kph / 1.609344) * 10) / 10;
				
			  });
			}],
			link: function (scope, element, attrs, ctrl) {
				'use strict';
							
				var state;
				var all;

				var myStorage = localStorage;

				var timer = 0
				, prevTime = performance.now()
				, curTime = prevTime
				, count = 0
				, totalDistance = 0
				, range = 0
				;
				
				var formatter = new Intl.NumberFormat('en-US', {
				  style: 'currency',
				  currency: 'USD',
				});
				
				scope.optionsIsActive = false;
				/*
				scope.fontSize = 100;
				scope.lineHeight = 120;
				scope.blockSpacing = 0.5;
				scope.dividerSpacing = 0.1;
				*/

				
				scope.settingsValuesInit = {
					"fontSize": 100,
					"lineHeight": 120,
					"blockSpacing": 0.5,
					"dividerSpacing": 0.1,
					"hideGeneral": false,
					"hideSpeed": false,
					"hideGears": false,
					"hideTemperature": false,
					"hidePitch": false,
					"hideFuel": false,
					"hideDistance": false,
					"hideEconomy": false,
					"hideDamage": false,
					"hideBeamDamage": false,
					"hideTorsionbarDamage": false,
					"hidePoints": true,
					"hideStreetcredits": false,
					"hideLeaderboard": true
					};


				element.ready(function () {
					scope.fontSize = scope.settingsValuesInit["fontSize"];
							scope.lineHeight = scope.settingsValuesInit["lineHeight"];
							scope.blockSpacing = scope.settingsValuesInit["blockSpacing"];
							scope.dividerSpacing = scope.settingsValuesInit["dividerSpacing"];
							scope.hideGeneral = scope.settingsValuesInit["hideGeneral"];
							scope.hideSpeed = scope.settingsValuesInit["hideSpeed"];
							scope.hideGears = scope.settingsValuesInit["hideGears"];
							scope.hideTemperature = scope.settingsValuesInit["hideTemperature"];
							scope.hidePitch = scope.settingsValuesInit["hidePitch"];
							scope.hideFuel = scope.settingsValuesInit["hideFuel"];
							scope.hideDistance = scope.settingsValuesInit["hideDistance"];
							scope.hideEconomy = scope.settingsValuesInit["hideEconomy"];
							scope.hideDamage = scope.settingsValuesInit["hideDamage"];
							scope.hideBeamDamage = scope.settingsValuesInit["hideBeamDamage"];
							scope.hideTorsionbarDamage = scope.settingsValuesInit["hideTorsionbarDamage"];
							scope.hidePoints = scope.settingsValuesInit["hidePoints"];
							scope.hideStreetcredits = scope.settingsValuesInit["hideStreetcredits"];
							scope.hideLeaderboard = scope.settingsValuesInit["hideLeaderboard"];
					// [4] Call the getSettings() function of the controller
					/*ctrl.getSettings()
					  .then(function (settings) {
						//console.log(settings);
						if (settings == null) {
							scope.fontSize = scope.settingsValuesInit["fontSize"];
							scope.lineHeight = scope.settingsValuesInit["lineHeight"];
							scope.blockSpacing = scope.settingsValuesInit["blockSpacing"];
							scope.dividerSpacing = scope.settingsValuesInit["dividerSpacing"];
							scope.hideGeneral = scope.settingsValuesInit["hideGeneral"];
							scope.hideSpeed = scope.settingsValuesInit["hideSpeed"];
							scope.hideGears = scope.settingsValuesInit["hideGears"];
							scope.hideTemperature = scope.settingsValuesInit["hideTemperature"];
							scope.hidePitch = scope.settingsValuesInit["hidePitch"];
							scope.hideFuel = scope.settingsValuesInit["hideFuel"];
							scope.hideDistance = scope.settingsValuesInit["hideDistance"];
							scope.hideEconomy = scope.settingsValuesInit["hideEconomy"];
							scope.hideDamage = scope.settingsValuesInit["hideDamage"];
							scope.hideBeamDamage = scope.settingsValuesInit["hideBeamDamage"];
							scope.hideTorsionbarDamage = scope.settingsValuesInit["hideTorsionbarDamage"];
							scope.hidePoints = scope.settingsValuesInit["hidePoints"];
							scope.hideStreetcredits = scope.settingsValuesInit["hideStreetcredits"];
							scope.hideLeaderboard = scope.settingsValuesInit["hideLeaderboard"];
							ctrl.saveSettings(scope.settingsValuesInit);
						} else {
							scope.fontSize = settings.fontSize;
							scope.lineHeight = settings.lineHeight;
							scope.global = {"line-height": scope.lineHeight + '%'};
							scope.blockSpacing = settings.blockSpacing;
							scope.dividerSpacing = settings.dividerSpacing;
							scope.hideGeneral = settings.hideGeneral;
							scope.hideSpeed = settings.hideSpeed;
							scope.hideGears = settings.hideGears;
							scope.hideTemperature = settings.hideTemperature;
							scope.hidePitch = settings.hidePitch;
							scope.hideFuel = settings.hideFuel;
							scope.hideDistance = settings.hideDistance;
							scope.hideEconomy = settings.hideEconomy;
							scope.hideDamage = settings.hideDamage;
							scope.hideBeamDamage = settings.hideBeamDamage;
							scope.hideTorsionbarDamage = settings.hideTorsionbarDamage;
							scope.hidePoints = settings.hidePoints;
							scope.hideStreetcredits = settings.hideStreetcredits;
							scope.hideLeaderboard = settings.hideLeaderboard;
						}
						//console.log(settings[scope.vehicleName]);
						//totalDistance = settings[scope.vehicleName];
					  })*/
				  });
					
				
				
				
				scope.openOptions = function() {
					scope.optionsIsActive = !scope.optionsIsActive;
				} 

				scope.resetOptions = function() {
					scope.fontSize = 100;
					scope.lineHeight = 120;
					scope.global = {"line-height": scope.lineHeight + '%'};
					scope.blockSpacing = 0.5;
					scope.dividerSpacing = 0.1;
					scope.hideGeneral = false;
					scope.hideSpeed = false;
					scope.hideGears = false;
					scope.hideTemperature = false;
					scope.hidePitch = false;
					scope.hideFuel = false;
					scope.hideDistance = false;
					scope.hideEconomy = false;
					scope.hideDamage = false;
					scope.hideBeamDamage = false;
					scope.hideTorsionbarDamage = false;
					scope.hidePoints = true;
					scope.hideStreetcredits = false;
					scope.hideLeaderboard = true;
				} 
				
				scope.saveOptions = function() {
					/*localStorage.setItem("EH-fontSize", scope.fontSize);
					localStorage.setItem("EH-lineHeight", scope.lineHeight);
					localStorage.setItem("EH-blockSpacing", scope.blockSpacing);
					localStorage.setItem("EH-dividerSpacing", scope.dividerSpacing);*/
					//console.log(scope.fontSize + " + " + scope.settingsValuesInit);
					scope.settingsValuesInit["fontSize"] = scope.fontSize;
					scope.settingsValuesInit["lineHeight"] = scope.lineHeight;
					scope.settingsValuesInit["blockSpacing"] = scope.blockSpacing;
					scope.settingsValuesInit["dividerSpacing"] = scope.dividerSpacing;
					scope.settingsValuesInit["hideGeneral"] = scope.hideGeneral;
					scope.settingsValuesInit["hideSpeed"] = scope.hideSpeed;
					scope.settingsValuesInit["hideGears"] = scope.hideGears;
					scope.settingsValuesInit["hideTemperature"] = scope.hideTemperature;
					scope.settingsValuesInit["hidePitch"] = scope.hidePitch;
					scope.settingsValuesInit["hideFuel"] = scope.hideFuel;
					scope.settingsValuesInit["hideDistance"] = scope.hideDistance;
					scope.settingsValuesInit["hideEconomy"] = scope.hideEconomy;
					scope.settingsValuesInit["hideDamage"] = scope.hideDamage;
					scope.settingsValuesInit["hideBeamDamage"] = scope.hideBeamDamage;
					scope.settingsValuesInit["hideTorsionbarDamage"] = scope.hideTorsionbarDamage;
					scope.settingsValuesInit["hidePoints"] = scope.hidePoints;
					scope.settingsValuesInit["hideStreetcredits"] = scope.hideStreetcredits;
					scope.settingsValuesInit["hideLeaderboard"] = scope.hideLeaderboard;
					//ctrl.saveSettings(scope.settingsValuesInit);
				} 
				
				scope.increaseFontSize = function() {
					scope.fontSize = scope.fontSize + 1;
					//console.log(appSettings);
					//ctrl.saveSettings(appSettings);
				} 
				
				scope.decreaseFontSize = function() {
					scope.fontSize = scope.fontSize - 1;
				} 
				
				scope.increaseLineHeight = function() {
					scope.global = {"line-height": (scope.lineHeight = scope.lineHeight + 5) + '%'};
				} 
				
				scope.decreaseLineHeight = function() {
					scope.global = {"line-height": (scope.lineHeight = scope.lineHeight - 5) + '%'};
				}

				scope.increaseBlockSpacing = function() {
					scope.blockSpacing = Math.round((scope.blockSpacing + 0.1) * 10) / 10;
				} 
				
				scope.decreaseBlockSpacing = function() {
					scope.blockSpacing = Math.round((scope.blockSpacing - 0.1) * 10) / 10;
				}
				
				scope.increaseDividerSpacing = function() {
					scope.dividerSpacing = Math.round((scope.dividerSpacing + 0.1) * 10) / 10;
				} 
				
				scope.decreaseDividerSpacing = function() {
					scope.dividerSpacing = Math.round((scope.dividerSpacing - 0.1) * 10) / 10;
				} 
				
							
				scope.progress = 0;
				scope.progress2 = 0;
				scope.progressEst = 0;
				scope.progress2Est = 0;
				scope.fuelPercent = 0;
				scope.fuelCap = 0;
				scope.fuelVol = 0;
				scope.fuelLperKM = 0;
				scope.fuelKMperL = 0;
				scope.fuelMperG = 0;
				
				scope.tSpeed = 0;
				scope.tSpeed2 = 0;
				
				scope.endurancePoints = 0;

				var intervalId;

				// assign vehicleName to currently stored value in VehicleService
				bngApi.engineLua("core_vehicles.getCurrentVehicleDetails()", function(vehicle) {
						scope.$evalAsync(function() {
							// save current vehicle key
							VehicleService.setVehicleName(vehicle.current.key);
							scope.vehicleName = VehicleService.getVehicleName();
							//console.log("VehicleInit");

						})
					})
				
				scope.$on("VehicleReset", function(event, data) {
					// get current vehicle
					bngApi.engineLua("core_vehicles.getCurrentVehicleDetails()", function(vehicle) {
						scope.$evalAsync(function() {
							// save current vehicle key
							VehicleService.setVehicleName(vehicle.current.key);
							scope.vehicleName = VehicleService.getVehicleName();
							//console.log("VehicleReset");
						})
					})
				});
				
				scope.$on("VehicleChange", function(event, data) {
					// get current vehicle
					bngApi.engineLua("core_vehicles.getCurrentVehicleDetails()", function(vehicle) {
						scope.$evalAsync(function() {
							// save current vehicle key
							VehicleService.setVehicleName(vehicle.current.key);
							scope.vehicleName = VehicleService.getVehicleName();
							//console.log("VehicleChange");
							//console.log("VehicleChange: " + scope.vehicleConfig + " - Distance: " + totalDistance + " Alternate Name:" + scope.vehicleName);
						})
					})
				});

				scope.$on('VehicleFocusChanged', function (event, data) {
					// get current vehicle
					bngApi.engineLua("core_vehicles.getCurrentVehicleDetails()", function(vehicle) {
						scope.$evalAsync(function() {
							// save current vehicle key
							VehicleService.setVehicleName(vehicle.current.key);
							scope.vehicleName = VehicleService.getVehicleName();
							clearInterval(intervalId) 
							intervalId = window.setInterval(function(){
								/// call your function here
								bngApi.queueAllObjectLua('extensions.separatedistancecounter.getAllVar()');
							  }, 5000);
							//console.log("VehicleFocusChanged");
						})
					})
				});

				scope.$on('updatePhysicsState', function (event, data) {
					if (data) {
					  curTime = performance.now();
					}
				});
				

				scope.leaderboard = [];
				scope.filteredLeaderboard = "";

				var array = [], //{ name: 'test1', id: 1, data: { a: 1 } }, { name: 'test2', id: 2, data: { a: 2 } } 
					object = {}, // name: 'test3', id: 3, data: { a: 3 } 
					index,
					keys;

					scope.$on('sendAllState', function (event, data) {

						all = data;
	
						//console.log("State " + JSON.stringify(state));
						//console.log("carConfig " + all.carConfig2);
						
	
						index = scope.leaderboard.findIndex(({ carConfig2 }) => carConfig2 == all.carConfig2);
	
						if (index === -1) {
							scope.leaderboard.push(all);
							//console.log("Car added");
						} else {
							scope.leaderboard[index] = all;
							//console.log("Car already added");
							//localStorage.setItem(all.carConfig2, all.progress2);
						}
	
						//console.log("Board " + JSON.stringify(scope.leaderboard));
	
	
	
						scope.leaderboard.sort(function(a, b) {
							return b.progress2 - a.progress2;
						});
	
						/*keys = scope.leaderboard.map(function(o,i) {
							return o.progress;
						  });
	
						console.log(keys);*/
	
						//scope.filteredLeaderboard = keys;
	
						scope.filteredLeaderboard = scope.leaderboard.map(({ progress2, carConfig2 }) => ({
							progress2, 
							carConfig2
						}));
						
						
						scope.$apply();
					});	


				scope.$on('sendState', function (event, data) {

					state = data;
					
					scope.vehicleModel = data.carModel;
					scope.vehicleConfig = data.carConfig;
					
					scope.tSpeed = Math.round(data.tSpeed * 10) / 10;
					scope.tSpeed2 = Math.round((data.tSpeed / 1.609344) * 10) / 10;
				  
					scope.progress = Math.round((data.progress / 1000) * 100) / 100;
					scope.progress2 = Math.round((data.progress / 1609.3440057765) * 100) / 100;
					scope.progressEst = Math.round(((scope.fuelVol / scope.fuelLperKM) * 100) * 10) / 10;
					scope.progressEst2 = Math.round((scope.progressEst / 1.6093440057765) * 10) / 10;
					
					scope.fuelPercent = Math.round((data.fuelPercent * 100) * 10) / 10;
					scope.fuelCap = data.fuelCap;
					scope.fuelVol = Math.round(data.fuelVol * 100) / 100;
					scope.fuelLperKM = Math.round((((scope.fuelCap - scope.fuelVol) / scope.progress) * 100) * 10) / 10;
					scope.fuelKMperL = Math.round((scope.progress / (scope.fuelCap - scope.fuelVol)) * 10) / 10;
					scope.fuelMperG = Math.round((235.214583 / scope.fuelLperKM) * 10) / 10;
					
					scope.endurancePoints = formatter.format(((data.progress / scope.fuelLperKM * (100 - scope.beams.deformed.percentage)) * (scope.tSpeed / 100)));
					
					scope.$apply();
				});	
				
				intervalId = window.setInterval(function(){
					/// call your function here
					bngApi.queueAllObjectLua('extensions.separatedistancecounter.getAllVar()');
				  }, 5000);

				scope.$on('$destroy', function () {
					/*scope.settingsValuesInit["fontSize"] = scope.fontSize;
					scope.settingsValuesInit["lineHeight"] = scope.lineHeight;
					scope.settingsValuesInit["blockSpacing"] = scope.blockSpacing;
					scope.settingsValuesInit["dividerSpacing"] = scope.dividerSpacing;
					ctrl.saveSettings(scope.settingsValuesInit);*/
					//console.log("Endsave: " + JSON.stringify(scope.settingsValuesInit));
				  });

				scope.$on('streamsUpdate', function (event, streams) {
					scope.$evalAsync(function () {

						bngApi.activeObjectLua('extensions.separatedistancecounter.getVar()');
						//bngApi.queueAllObjectLua('extensions.separatedistancecounter.getAllVar()');
						
						

						if (streams.electrics && streams.engineInfo) {
							var wheelSpeed = streams.electrics.wheelspeed;

							/*if (isNaN(parseFloat(localStorage.getItem(scope.vehicleConfig)))) {
								localStorage.setItem(scope.vehicleConfig, 0.0);
							}	else { 
								totalDistance = parseFloat(localStorage.getItem(scope.vehicleConfig));
								
							}*/
			  
							prevTime = curTime;
			  
							curTime = performance.now();
							timer -= 0.001 * (curTime - prevTime);
			  
							if (timer < 0) {
							  totalDistance += ((1.0 - timer) * wheelSpeed);
							  count++;
							  timer = 1;
							  //console.log("Written Config2: " + scope.vehicleConfig + " - Distance: " + totalDistance);
							  //localStorage.setItem(scope.vehicleConfig, totalDistance);
							}
			  
							
						  }
						
					});
				});
								
			}
		};
}])
