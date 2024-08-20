angular.module('beamng.apps').directive('eccSettings', [function () {
	return {
		templateUrl: '/ui/modules/apps/eccSettings/app.html',
		replace: true,
		restrict: 'EA',
		link: function (scope, element, attrs) {
		    scope.showDiv = true;

			bngApi.engineLua('settings.getValue("eccMaxFov", 76)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccMaxFov = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccCamDist", 0)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccCamDist = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccCamHeight", 0)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccCamHeight = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccCamAngle", 15)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccCamAngle = data;
		      });
		    });

			bngApi.engineLua('settings.getValue("eccFxShake", 1)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccFxShake = data;
		      });
		    });

			bngApi.engineLua('settings.getValue("eccFxGforceX", 1)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccFxGforceX = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccFxGforceY", 1)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccFxGforceY = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccFxGforceZ", 1)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccFxGforceZ = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccFxVelX", 1)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccFxVelX = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccFxVelY", 1)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccFxVelY = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccFxVelZ", 1)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccFxVelZ = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccFxRoll", 1)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccFxRoll = data;
		      });
		    });

		    bngApi.engineLua('settings.getValue("eccFxZbounce", true)', function (data) {
		      scope.$evalAsync(function () {
		        scope.eccFxZbounce = data;
		      });
		    });

			scope.$on('$destroy', function () {
			});

//			scope.$watch('showDiv', function () {
//			    scope.showDiv = !scope.showDiv;
//			})

			scope.$watch('eccMaxFov', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccMaxFov",'+newVal+')');
				}
			});

			scope.$watch('eccCamDist', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccCamDist",'+newVal+')');
				}
			});

			scope.$watch('eccCamHeight', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccCamHeight",'+newVal+')');
				}
			});

			scope.$watch('eccCamAngle', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccCamAngle",'+newVal+')');
				}
			});

			scope.$watch('eccFxShake', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccFxShake",'+newVal+')');
				}
			});

			scope.$watch('eccFxGforceX', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccFxGforceX",'+newVal+')');
				}
			});

			scope.$watch('eccFxGforceY', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccFxGforceY",'+newVal+')');
				}
			});

			scope.$watch('eccFxGforceZ', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccFxGforceZ",'+newVal+')');
				}
			});

			scope.$watch('eccFxVelX', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccFxVelX",'+newVal+')');
				}
			});

			scope.$watch('eccFxVelY', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccFxVelY",'+newVal+')');
				}
			});

			scope.$watch('eccFxVelZ', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccFxVelZ",'+newVal+')');
				}
			});

			scope.$watch('eccFxRoll', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccFxRoll",'+newVal+')');
				}
			});

			scope.$watch('eccFxZbounce', function (newVal, oldVal) {
				if(newVal !== undefined) {
					bngApi.engineLua('settings.setValue("eccFxZbounce",'+newVal+')');
				}
			});

			scope.resetSettings = function(){
				bngApi.engineLua('settings.setValue("eccMaxFov", 76)');
				bngApi.engineLua('settings.setValue("eccCamDist", 0)');
				bngApi.engineLua('settings.setValue("eccCamHeight", 0)');
                bngApi.engineLua('settings.setValue("eccCamAngle", 15)');
				bngApi.engineLua('settings.setValue("eccFxShake", 1)');
				bngApi.engineLua('settings.setValue("eccFxGforceX", 1)');
				bngApi.engineLua('settings.setValue("eccFxGforceY", 1)');
                bngApi.engineLua('settings.setValue("eccFxGforceZ", 1)');
				bngApi.engineLua('settings.setValue("eccFxVelX", 1)');
				bngApi.engineLua('settings.setValue("eccFxVelY", 1)');
				bngApi.engineLua('settings.setValue("eccFxVelZ", 1)');
				bngApi.engineLua('settings.setValue("eccFxRoll", 1)');
				bngApi.engineLua('settings.setValue("eccFxZbounce", true)');
				scope.eccMaxFov = 76;
				scope.eccCamDist = 0;
				scope.eccCamHeight = 0;
				scope.eccCamAngle = 15;
				scope.eccFxGforceX = 1;
				scope.eccFxGforceY = 1;
				scope.eccFxGforceZ = 1;
				scope.eccFxShake = 1;
				scope.eccFxVelX = 1;
				scope.eccFxVelY = 1;
				scope.eccFxVelZ = 1;
				scope.eccFxRoll = 1;
				scope.eccFxZbounce = true;
			};

			scope.showHide = function() {
				scope.showDiv = !scope.showDiv;
			};
		}
	};
}])
