#universal module definition
umd = (root, factory) ->
  if typeof define is "function" and define.amd
    define(["angular", "d3", "lodash"], factory)
  else if typeof exports is "object"
    module.exports = factory(require("angular"), require("d3"), require("lodash"))
  else
    root.triangularjs = factory(root.angular, root.d3, root._)

#the actual module
umd(this, (angular, d3, _) ->
  angular.module('triangular', [])
  .factory 'd3ng', ($rootScope) ->
    return {
    animatePath: (newValue, oldValue, duration, updateFrame) ->
      start = null
      interpolate = d3.interpolateArray(oldValue, newValue)

      step = (now) ->
        start ?= now
        progress = now - start
        if (progress < duration)
          requestAnimationFrame(step)
          $rootScope.$apply ->
            updateFrame(interpolate(progress/duration))
          #console.log progress/duration, interpolate(progress/duration)
        else
          $rootScope.$apply ->
            updateFrame(interpolate(1))

      requestAnimationFrame(step)
    }

  .directive "axis", ($parse) ->
    return {
    restrict: 'A'
    scope: {
      scale: '='
      orient: '@'
      ticks: '='
      tickValues: '='
      tickSubdivide: '='
      tickSize: '='
      tickPadding: '='
      tickFormat: '@'
    }
    link: (scope, element) ->
      scope.tickFormat = ($parse scope.tickFormat)(d3: d3)
      axis = d3.svg.axis()

      scope.$watch "attrs", ->
        parameters = ['scale', 'orient', 'ticks', 'tickValues', 'tickSubdivide', 'tickSize', 'tickPadding', 'tickFormat']
        for p in parameters when scope[p]
          axis[p](scope[p])
        axis(element)

      scope.$watch 'scale.domain()', ->
        axis.scale(scope.scale)
        d3.select(element[0]).transition().duration(750).call(axis)
    }

  .directive "lineChart", (d3ng) ->
    return {
    restrict: "E"
    templateUrl: "template/lineChart.html"
    scope:
      width: '='
      height: '='
      marginLeft: '='
      marginRight: '='
      marginTop: '='
      marginBottom: '='
      ticksX: '='
      ticksY: '='
      textX: '='
      textY: '='
      data: '='
      lineColour: '='
      lineWidth: '='
    link: (scope) ->

      scope.total_subs_line = "M0,0"

      scope.$watch "data", (val, oldVal) ->
        scope.x = d3.scale.linear().range([0, scope.width - scope.marginLeft - scope.marginRight])
        scope.y = d3.scale.linear().range([scope.height - scope.marginTop - scope.marginBottom, 0])

        scope.x.domain(d3.extent(val, (d, i) -> i))
        scope.y.domain(d3.extent(val, (d) -> d))

        scope.line = d3.svg.line()
        .x((d, i) -> scope.x(i))
        .y((d) -> scope.y(d))
        .interpolate("cardinal")

        if _.some(val, _.isNaN)
          scope.total_subs_line = "M0,0"
        else if val
          val = val.map Math.round
          oldVal = ((if item then item else 0) for item in oldVal)

          d3ng.animatePath val, oldVal, 750, (value) ->
            scope.total_subs_line = scope.line(value)
        else
          console.warn "not implemented", val
    }

  .directive 'svgDragX', ($document, $parse) ->
    (scope, element, attr) ->
      startX = 0
      x = 0
      svgRootX = 0
      targetX = $parse(attr.svgDragX)

      element.on 'mousedown', (event) ->
        # Prevent default dragging of selected content
        event.preventDefault()

        svgRootX = targetX(scope)
        startX = event.screenX

        $document.on('mousemove', mousemove)
        $document.on('mouseup', mouseup)

      mousemove = (event) ->
        x = event.screenX - startX
        targetX.assign(scope, x + svgRootX)
        scope.$parent.$parent.$digest()

      mouseup = ->
        $document.off('mousemove', mousemove)
        $document.off('mouseup', mouseup)

  .directive 'svgDragY', ($document, $parse) ->
    (scope, element, attr) ->
      startY = 0
      y = 0
      svgRootY = 0
      targetY = $parse(attr.svgDragY)

      element.on 'mousedown', (event) ->
        # Prevent default dragging of selected content
        event.preventDefault()

        svgRootY = targetY(scope)
        startY = event.screenY

        $document.on('mousemove', mousemove)
        $document.on('mouseup', mouseup)

      mousemove = (event) ->
        y = event.screenY - startY
        targetY.assign(scope, y + svgRootY)
        scope.$parent.$parent.$digest()

      mouseup = ->
        $document.off('mousemove', mousemove)
        $document.off('mouseup', mouseup)
)