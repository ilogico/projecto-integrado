"use strict"
class Heap
	bubbleDown = (a, i, comp)->
		val = a[i]
		parent_idx = i - 1 >> 1
		while i > 0
			parent = i - 1 >> 1
			if comp(a[parent], val) > 0
				a[i] = a[parent]
				i = parent
			else
				break
		a[i] = val
		undefined

	bubbleUp = (a, comp)->
		i = 0
		value = a[0]
		l = a.length
		loop
			leftChild = (i << 1) + 1
			if leftChild >= l
				break
			rightChild = leftChild + 1
			if rightChild >= l or comp(a[leftChild], a[rightChild]) < 0
				child = leftChild
			else
				child = rightChild
			if comp(a[child], value) < 0
				a[i] = a[child]
				i = child
			else
				break
		a[i] = value
		undefined

	heapify = @heapify = (a, comp)->
		i = 0
		l = a.length
		while i < l
			bubbleDown(a, i++, comp)
		undefined

	constructor: (@comp, @array = [])->

	push: (val)->
		l = @array.length
		@array.push val
		bubbleDown(@array, l, @comp)
		undefined

	pop: ->
		val = @array[0]
		@array[0] = @array.pop()
		bubbleUp(@array, @comp)
		val

	pushPop: (val)->
		if @array.length and @comp(@array[0], val) < 0
			ret = @array[0]
			@array[0] = val
			bubbleUp(@array, @comp)
			ret
		else
			val

	size: -> @array.length

module.exports = Heap