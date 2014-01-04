"use strict"
Huffman = require './huffman'
{Lengths, ExtraLengthBits} = do ->
	lengths = {}
	lbits = {}
	extra = 0
	l = 3
	for i in [257..264]
		lengths[i] = l++
		lbits[i] = 0
	extra = 1
	for i in [265..281] by 4
		for j in [i..i+3]
			lengths[j] = l
			lbits[j] = extra
			l += (1 << extra)
		extra++
	lengths[285] = 258
	lbits[285] = 0
	{Lengths: lengths, ExtraLengthBits: lbits}
{Distances, ExtraDistBits} = do ->
	distances = {}
	dbits = {}
	dist = 1
	for i in [0..3]
		distances[i] = dist++
		dbits[i] = 0
	extra = 1
	for i in [4..28] by 2
		distances[i] = dist
		dbits[i] = extra
		dist += 1 << extra
		distances[i + 1] = dist
		dbits[i + 1] = extra
		dist += 1 << extra
		extra++
	{Distances: distances, ExtraDistBits: dbits}

class BitStream
	constructor: (@array)->
		@idx = 0
		@canRead = true
		@refill()
		@bit = 0

	refill: ->
		@buffer = []
		@bit = 0
		i = @idx
		l = i + 100
		if l > @array.length
			l = @array.length
			@canRead = false
		while i < l
			byte = @array[i]
			j = 0
			while j < 8
				@buffer.push((byte >> j) & 1)
				j++
			i++
		@idx = l
		return

	readBit: ->
		bit = @buffer[@bit++]
		if @bit == @buffer.length
			@refill()
		bit

	readInt: (size)->
		v = 0
		while size--
			v = (v << 1) | @readBit()
		v

order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]

decode = (input)->
	input = new BitStream(input)
	output = []
	lastBlock = 0
	while !lastBlock
		lastBlock = input.readBit()
		blockType = input.readInt(2)
		if blockType != 2
			throw new Error("Unimplemented Block Type")
		else
			n_length = input.readInt(5) + 257
			n_dist = input.readInt(5) + 1
			n_meta = input.readInt(4) + 4

			meta_lengths = (0 for i in [0..18])
			for i in [0...n_meta]
				meta_lengths[order[i]] = input.readInt(3)

			meta_tree = Huffman.fromCodeLengths(meta_lengths)

			lit_lenghts = []
			dist_lengths = []
			last_length = 0
			meta_node = meta_tree
			while n_dist > 0
				while !meta_node.leaf
					meta_node = meta_node[input.readBit()]
				value = meta_node.value
				ammount = 1
				if value < 16
					last_length = value
				else if value == 16
					value = last_length
					ammount = 3 + input.readInt(2)
				else if value == 17
					value = last_length = 0
					ammount = 3 + input.readInt(3)
				else if value == 18
					value = last_length = 0
					ammount = 11 + input.readInt(7)
				for i in [0...ammount]
					if n_length > 0
						lit_lenghts.push value
						n_length--
					else
						dist_lengths.push value
						n_dist--
				meta_node = meta_tree

			lit_tree = Huffman.fromCodeLengths(lit_lenghts)
			dist_tree = Huffman.fromCodeLengths(dist_lengths)

			end_block = false
			count = 0
			while !end_block
				lit_node = lit_tree
				while !lit_node.leaf
					lit_node = lit_node[input.readBit()]
				code = lit_node.value

				if code < 256
					output.push code
				else if code == 256
					end_block = true
				else
					length = Lengths[code] + input.readInt(ExtraLengthBits[code])
					dist_node = dist_tree
					while !dist_node.leaf
						dist_node = dist_node[input.readBit()]
					dist_code = dist_node.value
					distance = Distances[dist_code] + input.readInt(ExtraDistBits[dist_code])

					idx = output.length - distance
					for i in [0...length]
						output.push output[i + idx]
	new Uint8Array(output)


module.exports = decode