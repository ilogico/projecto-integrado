"use strict"
class Heap
	bubbleDown = (a, i, comp)->
		val = a[i]
		while i > 0
			parent = i - 1 >> 1
			if comp(a[parent], val) > 0
				a[i] = a[parent]
				i = parent
			else
				break
		a[i] = val
		return

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
		return

	heapify = (a, comp)->
		i = 0
		l = a.length
		while i < l
			bubbleDown(a, i++, comp)
		return

	constructor: (@comp, @array = [])->
		heapify(@array, @comp)

	push: (val)->
		l = @array.length
		@array.push val
		bubbleDown(@array, l, @comp)
		return

	pop: ->
		if @array.length > 1
			val = @array[0]
			@array[0] = @array.pop()
			bubbleUp(@array, @comp)
			val
		else
			@array.pop()

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
