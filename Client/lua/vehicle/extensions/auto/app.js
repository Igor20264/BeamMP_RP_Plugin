angular.module('beamng.apps')
.directive('overtorque', [function () {
  return {
    template:
        `<div style="height:100%; font-family:Consolas,Monaco,Lucida Console,Liberation Mono; background-color:rgba(255,255,255,0.9)">
          <div layout="column" style="position: absolute; top: 20px; left: 70px; font-weight:bold;">
            <small style="color:#000000; padding:2px">Current</small>
            <small style="color:#FF0000; padding:2px">Rating</small>
            <small style="color:#FF4400; padding:2px">Damage</small>
            <small style="color:#0000FF; padding:2px">Boom</small>
          </div>

          <div layout="row" layout-align="start end">
            <div >
            <canvas style="position: relative; top:10px; left: 60px"></canvas>
            <div >
              <div style="right: -35px; bottom: 50%; transform: rotate(90deg); position: absolute;">
                {{:: 'ui.apps.engine_dynamometer.torque' | translate}} ({{torqueUnit}})
              </div>
              <div layout="column" ng-repeat="l in tickLabels" style="text-align: justify; right:40px; position: absolute; top: {{ $index*tickSpacing }}px">
                {{ (globalMax - $index*tickInterval).toFixed(0) }}
              </div>
            </div>
          </div>
        </div>`,
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var streamsList = ['overtorque']
      StreamsManager.add(streamsList)
      scope.$on('$destroy', function () {
        StreamsManager.remove(streamsList)
      })

      scope.tickLabels = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
      scope.globalMax = 0
	  scope.currentMax = 0

      // scope.globalMin = 0

      var chart = new SmoothieChart({
          minValue: 0,
          maxValue: 1000,
          millisPerPixel: 20,
          interpolation: 'bezier',
          grid: { fillStyle: 'rgba(250,250,250,0.2)', strokeStyle: 'grey', verticalSections: 20, millisPerLine: 1000, sharpLines: true },
          labels: {disabled: true}
        })
        , currentGraph = new TimeSeries()
        , currentMaxGraph = new TimeSeries()
        , ratingGraph = new TimeSeries()
        , damageGraph = new TimeSeries()
        , boomGraph = new TimeSeries()


      var canvas = element[0].getElementsByTagName('canvas')[0]

      scope.tickSpacing = canvas.height / 10
      //var powerFactor = Math.PI * 1.341 / 30000
      chart.addTimeSeries(currentGraph,        {strokeStyle: '#000000', lineWidth: 1.5})
      chart.addTimeSeries(currentMaxGraph,        {strokeStyle: '#000000', lineWidth: 1.5})
      chart.addTimeSeries(ratingGraph, {strokeStyle: '#FF0000', lineWidth: 1.5})
      chart.addTimeSeries(damageGraph, {strokeStyle: '#FF4400', lineWidth: 1.5})
      chart.addTimeSeries(boomGraph,       {strokeStyle: '#0000FF', lineWidth: 1.5})
      chart.streamTo(canvas, 40)

      scope.$on('streamsUpdate', function (event, streams) {
        if (streams) {
          var xPoint = new Date()
          var Tcurrent = streams.overtorque.current,
            Trating = streams.overtorque.rating,
			Tdamage = streams.overtorque.damage,
			Tlimit = streams.overtorque.limit

            scope.torqueUnit = UiUnits.torque().unit
            //scope.powerUnit = UiUnits.power().unit
          // scope.torqueUnit =

			scope.currentMax = Math.max(scope.currentMax, Tcurrent)

          scope.$applyAsync(function () {
            scope.globalMax = Math.ceil(Math.max.apply(null, [scope.globalMax, Trating, Tlimit]) / 100) * 100
            //scope.globalMin = Math.floor(Math.min.apply(null, [scope.globalMin, torque, power, rpm]) / 100) * 100
            // scope.globalMin = 0
            scope.tickInterval = (scope.globalMax - /*scope.globalMin*/ 0) / 10
          })
          chart.options.maxValue = scope.globalMax
          // chart.options.minValue = scope.globalMin

          currentGraph.append(xPoint, Tcurrent)
          currentMaxGraph.append(xPoint, scope.currentMax)
          ratingGraph.append(xPoint, Trating)
          damageGraph.append(xPoint, Tdamage)
          boomGraph.append(xPoint, Tlimit)
        }
      })

      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width - 130
        canvas.height = data.height - 20
        scope.tickSpacing = canvas.height / 10
      })

    }
  }
}])