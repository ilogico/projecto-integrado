"use strict"

HuffmanTree = require 'huffman'
{BitStream} = require 'bitstream'

class DeflateDecoder

	class CompressedParser
		{Lengths, ExtraLengthBits} = do ->
			lenghts = {}
			lbits = {}
			extra = 0
			l = 3
			for i in [257..264]
				lengths[i] = l++
				lbits = 0
			extra = 1
			for i in [265..281 by 4]
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
			for i in [4..28 by 2]
				distances[i] = dist
				dbits[i] = extra
				dist += 1 << extra
				distances[i + 1] = dist
				dbits[i + 1] = extra
				dist += 1 << extra
				extra++
			{Distances: distances, ExtraDistBits: dbits}

		constructor: (@decoder, @litTree, @distTree)->
			@litNode = @litTree
			@extraLengthBits = 0
			@extraLength = 0
			@distNode = @distTree
			@extraDistBits = 0
			@extraDist = 0

		parse: (bit)->
			if @litNode.leaf
				if @extraLengthBits > 0
					@extraLength = (@extraLength << 1) | bit
					@extraLengthBits--
				else if @distNode.leaf
					@extraDist = (@extraDist << 1) | bit
					@extraDistBits--
					if @extraDistBits == 0
						@copy
				else
					@distNode = @distNode[bit]
					if @distNode.leaf
						distCode = @distNode.value
						@extraDistBits == ExtraDistBits[distCode]
						if @extraDistBits == 0
							@copy()
			else
				@litNode = @litNode[bit]
				if @litNode.leaf
					value = @litNode.value
					if value < 256
						@litNode = @litTree
						@decoder.window.push value
						@decoder.output.push value
						@decoder.normalizeWindow()
					else if value == 256
						if @decoder.lastBlock
							@decoder.end()
						else
							@decoder.parser = new PreBlockParser(@decoder)
					else
						@extraLengthBits = ExtraLengthBits[value]
						@extraLength = 0
						@distNode = @distTree
			undefined
		copy: ->
			distance = Distances[@distNode.value] + @extraDist
			length = Lengths[@litNode.value] + @extraLength
			idx = @decoder.window.length - distance
			while idx < length
				byte = @decoder.window[idx++]
				@decoder.window.push byte
				@decoder.output.push byte
			@decoder.normalizeWindow()
			@litNode = @litTree
			undefined

	class DynamicTreeParser
		HclenOrder = [
			16
			17
			18
			0
			8
			7
			9
			6
			10
			5
			11
			4
			12
			3
			13
			2
			14
			1
			15
		]
		constructor: (@decoder)->
			@hlit = 0
			@hlitBits = 5
			@hdist = 0
			@hdistBits = 5
			@hclen = 0
			@hclenBits = 4
			@metaCount = 0
			@metaLengths = []
			@metaTree = null
			@metaNode = null
			@litLengths = []
			@distLengths = []
			@curInt = 0
			@curBits = 3
			@lastLength = 0

		parse: (bit)->
			if @hlitBits > 0
				@hlit = (@hlit << 1) | bit
				@hlitBits--
			else if @hdistBits > 0
				@hdist = (@hdist << 1) | bit
				@hdistBits--
			else if @hclenBits > 0
				@hclen = (@hclen << 1) | bit
				@hclenBits--
				if @hclenBits == 0
					@hlit += 257
					@hdist += 1
					@hclen += 4
			else if @metaCount < @hclen
				@curInt = (@curInt << 1) | bit
				@curBits--
				if @curBits == 0
					@metaLengths[HclenOrder[@metaCount]] = @curInt
					@curInt = 0
					@curBits = 3
					@metaCount++
					if @metaCount == @hclen
						@metaTree = HuffmanTree.fromCodeLengths(@metaLengths)
						@metaNode = @metaTree

			else
				if @metaNode.leaf
					@curInt = (@curInt << 1) | bit
					@curBits--
					if @curBits == 0
						a = if @hlit > 0
							@hlit--
							@litLengths
						else
							@hdist--
							@distLengths
						code = @metaNode.value
						if code == 16
							for i in [0..3+@curInt]
								a.push @lastLength
						else if code == 17
							for i in [0..3+@curInt]
								a.push 0
						else
							for i in[0..11+@curInt]
								a.push 0
						if @hlit == 0 and @hdist == 0
							litTree = HuffmanTree.fromCodeLengths(@litLengths)
							distTree = HuffmanTree.fromCodeLengths(@distLengths)
							@decoder.parser = new CompressedParser(@decoder, litTree, distTree)
						else
							@metaNode = @metaTree
				else
					@metaNode = @metaNode[bit]
					if @metaNode.leaf
						code = @metaNode.value
						if code < 16
							a = 
								if @hlit > 0
									@hlit--
									@litLengths
								else
									@hdist--
									@distLengths
							a.push code
							if @hlit == 0 and @hdist == 0
								litTree = HuffmanTree.fromCodeLengths(@litLengths)
								distTree = HuffmanTree.fromCodeLengths(@distLengths)
								@decoder.parser = new CompressedParser(@decoder, litTree, distTree)
							else
								@metaNode = @metaTree
						else
							@curInt = 0
							@curBits =
								if code == 16
									2
								else if code == 17
									3
								else
									7
			undefined						

	class PreBlockParser
		constructor: (@decoder)->
			@bits = 3
			@buf = 0
		parse: (bit)->
			@bits--
			@buf = (@buf << 1) | bit
			if @bits == 0
				@decoder.lastBlock = @buf >> 2
				blockType = @buf & 3
				if blockType == 0
					@decoder.parser = new UncompressedParser(@decoder)
				else if blockType == 1
					@decoder.parser = new CompressedParser(@decoder, defaultLitTree, defaultDistTree)
				else if blockType == 2
					@decoder.parser = new DynamicTreeParser(@decoder)
				else
					throw new Error("Unsupported Format")
			undefined

	class UncompressedParser
		constructor: (@decoder)->
			@sizeBytes = 4
			@size = 0
			@decoder.byteMode()


		parse: (byte)->
			if @sizeBytes > 0
				@size = (@size << 8) | byte
				@sizeBytes--
				if @sizeBytes == 0
					size = @size >> 16
					if size != (@size & 0xffff) ^ 0xffff or size == 0
						throw new Error("Uncompressed Block Size Error")
					else
						@size = size
			else
				@decoder.window.push byte
				@decoder.output.push byte
				@decoder.normalizeWindow()
				@size--
				if @size == 0
					@decoder.input.bitMode()
					@decoder.parser = new PreBlockParser(@decoder)
			undefined


	class OutputQueue
		constructor: (@decoder)->
			@buff = []
			@decoder.canRead = false
		push: (byte)->
			@buff.push byte
			@decoder.canRead = true
			undefined
		pop: ->
			@decoder.canRead = @buf.length > 1
			@buf.shift()

	constructor: ->
		@input = new BitStream()
		@output = new OutputQueue(this)
		@parser = new PreBlockParser(this)
		@window = []

	MinWindowSize = Math.pow(2, 15)
	DMinWindowSize = 2 * MinWindowSize

	normalizeWindow: ->
		while @window.length > DMinWindowSize
			@window = @window.slice(MinWindowSize)
		undefined

	consume: ->
		while @input.canRead
			@parser.parse @input.read()
		undefined

	writeBuffer: (data)->
		@input.writeBuffer(data)
		@consume()

	writeByte: (byte)->
		@input.writeByte(byte)
		consume()

	end: ->
		@input.canRear = false