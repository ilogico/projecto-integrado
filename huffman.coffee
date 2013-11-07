"use strict"

Heap = require "heap"

class HuffmanNode
	constructor: (value)->
		if value?
			@value = value
			@leaf = true
		else
			@leaf = false

	@insertCode = (tree, code, codeLength, value)->
		codeLength--
		dir = (code >> codeLength) & 1
		while codeLength > 0
			tree[dir] or= new HuffmanNode()
			tree = tree[dir]
			codeLength--
			dir = (code >> codeLength) & 1
		tree[dir] = new HuffmanNode(value)
		undefined



class HuffmanBranch extends HuffmanNode
	constructor: (left, right)->
		@[0] = left
		@[1] = right
		@weight = left.weight + right.weight
		@leaf = false

class HuffmanLeaf extends HuffmanNode
	constructor: (@value, @weight)->

class HuffmanTree
	constructor: (@root)->

	comp = (n0, n1)->
		n0.weight - n1.weight

	@fromFrequencies = (a)->
		a = (new HuffmanLeaf(v, w) for w, v in a)
		h = new Heap(a)

		current = h.pop()

		while current.weight < 1
			current = h.pop()

		while h.size()
			current = h.pushPop(new HuffmanBranch(current, h.pop()))
	current

	@fromCodeLengths = (lengths, count)->
		if !count?
			count = []
			for l in lengths
				count[l] or= 0
				count[l]++


		tree = new HuffmanNode()
		count[0] = 0
		codes = [0]
		code = 0
		for l, value in [lengths][1..] when l > 0
			code = codes[l]++
			HuffmanNode.insertCode(tree, code, l, value)
		new HuffmanTree(tree)

	@defaultLit = ->
		lengths = []
		lengths.push(8) for i in [0..143]
		lengths.push(9) for i in [144..255]
		lengths.push(7) for i in [256..279]
		lengths.push(8) for i in [280..287]
		count = (0 for i in [0..6])
		count[7] = 24
		count[8] = 152
		count[9] = 112
		@fromCodeLengths(lengths, count)

	@defaultDist = ->
		lengths = (5 for i in [0..31])
		count = (0 for i in [0..4])
		count.push(32)
		@fromCodeLengths(lengths, count)

module.exports = HuffmanTree

