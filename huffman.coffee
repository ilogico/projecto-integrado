"use strict"

Heap = require "./heap"

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
		return




class HuffmanBranch extends HuffmanNode
	constructor: (left, right)->
		@[0] = left
		@[1] = right
		@weight = left.weight + right.weight
		@leaf = false

class HuffmanLeaf extends HuffmanNode
	constructor: (@value, @weight)->
		@leaf = true

class HuffmanTree

	comp = (n0, n1)->
		n0.weight - n1.weight

	codeLengthsFromTree = (tree, depth, buckets, excess, maxLength)->
		depth++
		if tree[0].leaf
			if depth > maxLength
				excess.push tree[0]
			else
				buckets[depth - 1].push tree[0]
		else
			codeLengthsFromTree(tree[0], depth, buckets, excess, maxLength)
		if tree[1].leaf
			if depth > maxLength
				excess.push tree[1]
			else
				buckets[depth - 1].push tree[1]
		else
			codeLengthsFromTree(tree[1], depth, buckets, excess, maxLength)
		return

	@codesFromTree = codesFromTree = (tree, depth, prefix, codes)->
		depth++
		for i in [0..1] when tree[i]?
			p = (prefix << 1) | i
			if tree[i].leaf
				codes[tree[i].value] =
					code: p
					length: depth
			else
				codesFromTree(tree[i], depth, p, codes)
		codes

	@fromFrequencies = (a, maxLength = 15)->
		size = a.length
		a = (new HuffmanLeaf(v, w) for w, v in a)
		h = new Heap(comp, a)

		current = h.pop()

		while current.weight < 1
			current = h.pop()

		while h.size()
			current = h.pushPop(new HuffmanBranch(current, h.pop()))


		# maximum symbol size is maxLength
		excess = []
		buckets = ([] for i in [0...maxLength])
		codeLengthsFromTree(current, 0, buckets, excess, maxLength)

		excess.sort(comp).reverse()
		bucket.sort(comp).reverse() for bucket in buckets

		i = maxLength - 2
		while excess.length
			while excess.length and buckets[i].length
				j = i + 1
				buckets[j].unshift buckets[i].pop()
				promote = 1
				while j < maxLength - 1
					next = j + 1
					k = promote
					while k > 0 and buckets[next].length
						buckets[j].push buckets[next].shift()
						k--
					promote += k * 2

					j = next
				while excess.length and promote
					buckets[maxLength - 1].push excess.shift()
					promote--

			i--

		count = [0]
		lengths = (0 for i in [0...size])
		for bucket, i in buckets
			l = i + 1
			count[l] = bucket.length
			for code in bucket
				lengths[code.value] = l

		###
		confirmation = Math.pow(2, maxLength)
		total = confirmation
		for length in lengths when length > 0
			confirmation -= (total >> length)
		# confirmation > 0
		###
		
		tree = fromCodeLengths(lengths)
		codesFromTree(tree, 0, 0, {})







	fromCodeLengths = @fromCodeLengths = (lengths, count, maxLength = 15)->
		if !count?
			count = []
			maxL = 0
			for l in lengths
				maxL = if l > maxL then l else maxL
				count[l] or= 0
				count[l]++
			for i in [0..maxL]
				count[i] or= 0

		tree = new HuffmanNode()
		count[0] = 0
		codes = [0]
		code = 0
		for i in [1..maxLength]
			code = (code + count[i - 1]) << 1
			codes[i] = code

		for l, value in lengths when l > 0
			code = codes[l]++
			HuffmanNode.insertCode(tree, code, l, value)
		tree

	@defaultLit = ->
		lengths = []
		lengths.push(8) for i in [0..143]
		lengths.push(9) for i in [144.. 255]
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

