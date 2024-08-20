angular.module('beamng.apps')
.directive('inputTelemetry', [function () {
  return {
    template:
        `<div style="height:100%; font-family:Consolas,Monaco,Lucida Console,Liberation Mono; background-color: rgba(50, 50, 50, 0.9)"">
       
          <div style="display:flex;">
            <canvas style="margin-left:10px;margin-top:10px;"></canvas> 
            <div style="width:5%;background-color:rgba(50, 50, 50, 0.9); margin-left:15px; margin-top:10px;transform: rotate(180deg)">
                <div style="height:100%;width:100%;background-color:#00008B;" id="clutch"></div>
            </div>
            <div style="width:5%;background-color:rgba(50, 50, 50, 0.9); margin-left:10px; margin-top:10px;transform: rotate(180deg)">
                <div style="height:100%;width:100%;background-color:#FF0000;" id="brake"></div>
            </div>
              <div style="width:5%;background-color:rgba(50, 50, 50, 0.9); margin-left:10px; margin-top:10px;transform: rotate(180deg)">
                
                <div style="height:100%;width:100%;background-color:#00FF00;" id="gas"></div>
                
            </div>
          </div>
          
        </div>`,
    replace: true,
    restrict: 'EA',
    link: function (scope, element, attrs) {
      var chart = new SmoothieChart({
          minValue: 0,
          maxValue: 100,
          millisPerPixel: 20,
          grid: { fillStyle: 'rgba(50, 50, 50, 0.9)', strokeStyle: 'rgba(20, 20, 20, 0.9)', verticalSections: 5, millisPerLine: 1000, sharpLines: true },
          labels: {disabled: true}
        })
        , gasGraph = new TimeSeries()
        , brakeGraph = new TimeSeries()
        , clutchGraph = new TimeSeries()
        , steeringGraph = new TimeSeries()


      var canvas = element[0].getElementsByTagName('canvas')[0]
      chart.addTimeSeries(clutchGraph, {strokeStyle: '#00008B', lineWidth: 3})
      chart.addTimeSeries(gasGraph, {strokeStyle: '#00FF00', lineWidth: 3})
      chart.addTimeSeries(brakeGraph, {strokeStyle: '#FF0000', lineWidth: 3})
      chart.addTimeSeries(steeringGraph, {strokeStyle: '#808080', lineWidth: 3})
      chart.streamTo(canvas, 40)
      chart.options.maxValue = 100;

      scope.$on('streamsUpdate', function (event, streams) {
          var xPoint = new Date();
          var clutchVal  = Math.round(streams.electrics.clutch * 100 + 0.49)
							, brakeVal    = Math.round(streams.electrics.brake * 100)
							, throttleVal = Math.round(streams.electrics.throttle * 100)
              , steeringVal = ((streams.electrics.steering_input*100).toFixed(1))/2+50
          document.getElementById("brake").style.height = brakeVal + "%";
          document.getElementById("clutch").style.height = clutchVal + "%";
          document.getElementById("gas").style.height = throttleVal + "%";
          
          gasGraph.append(xPoint, throttleVal);
          brakeGraph.append(xPoint, brakeVal);
          clutchGraph.append(xPoint, clutchVal);
          steeringGraph.append(xPoint, steeringVal);
      })

      scope.$on('app:resized', function (event, data) {
        canvas.width = data.width - 130
        canvas.height = data.height - 20
        scope.tickSpacing = canvas.height / 10
      })

    }
  }
}])