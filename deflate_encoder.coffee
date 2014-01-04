"use strict"

Huffman = require './huffman'
OutputStream = require './output_stream'

MinWindowSize = Math.pow(2, 15)

LengthCodes = do ->
	r = {}
	for i in [3..10]
		r[i] = {code: i + 254, extraBits: 0, extra: 0}

	extraBits = 1
	incrementExtra = 1
	maxOffset = 2
	offset = 0
	code = 265
	for i in [11..257]
		if offset == maxOffset
			offset = 0
			code++
			if incrementExtra % 4 == 0
				extraBits++
				maxOffset *= 2
			incrementExtra++
		r[i] = {code: code, extraBits: extraBits, extra: offset++}
	r[258] = {code: 285, extraBits: 0, extra: 0}
	r


length_code = (l)->
	# Just copy from the hashtable
	{code, extraBits, extra} = LengthCodes[l]
	{code, extraBits, extra}

DistCodes = do ->
	r = {}
	for i in [1..4]
		r[i] = {code: i - 1, extraBits: 0, extra: 0}

	extraBits = 1
	incrementExtra = 1
	maxOffset = 2
	offset = 0
	code = 4
	for i in [5..32768]
		if offset == maxOffset
			offset = 0
			code++
			if incrementExtra % 2 == 0
				extraBits++
				maxOffset *= 2
			incrementExtra++
		r[i] = {code: code, extraBits: extraBits, extra: offset++}
	r

dist_code = (d)->
	{code, extraBits, extra} = DistCodes[d]
	{code, extraBits, extra}
	
	
# ScanWindow = 32768
ScanWindow = Math.pow(2,10)

encode = (buffer)->
	output = []
	hashTable = {}
	lengthFreq = (0 for i in [0..285])
	distFreq = (0 for i in [0..29])
	i = 0
	l = buffer.length
	while i < l - 2
		hash = (buffer[i] << 16) + (buffer[i + 1] << 8) + buffer[i + 2]
		ocurrences = hashTable[hash]
		if ocurrences?
			to_discard = 0
			while to_discard < ocurrences.length and i - ocurrences[to_discard] > ScanWindow
				to_discard++
			if to_discard > 0
				ocurrences = hashTable[hash] = ocurrences.slice(to_discard)
		else
			ocurrences = hashTable[hash] = []
		if ocurrences.length > 0
			max_str = 3
			max_idx = ocurrences[0]
			for j in ocurrences
				k = 3
				while k < 258 and k + i < l and buffer[k+i] == buffer[k+j]
					k++
				if k >= max_str
					max_str = k
					max_idx = j

			code = length_code(max_str)
			code.distance = dist_code(i - max_idx)
			output.push code

			lengthFreq[code.code]++
			distFreq[code.distance.code]++

			# now we update the hash table with the values we'll skip
			end = max_str + i
			stop = Math.min(end, l - 2)
			hash = hash >> 8
			while i < stop
				hash = ((hash & 0xffff) << 8) | buffer[i + 2]
				oc = hashTable[hash] or []
				oc.push(i)
				hashTable[hash] = oc
				i++
			i = end
		else
			hashTable[hash] = [i]
			lengthFreq[buffer[i]]++
			output.push {code: buffer[i++]}

	# encode the remaining 1 or 2 bytes
	while i < l
		lengthFreq[buffer[i]]++
		output.push {code: buffer[i++]}

	output.push {code: 256}
	lengthFreq[256]++


	lengths = Huffman.fromFrequencies(lengthFreq)
	dists = Huffman.fromFrequencies(distFreq)

	# make dictionary

	# find highest codes
	maxLength = 256
	for k, v of lengths when +k > maxLength
		maxLength = +k

	maxDist = 0
	for k, v of dists when +k > maxDist
		maxDist = +k

	dictionary = []

	for i in [0..maxLength]
		if lengths[i]?
			dictionary.push lengths[i].length
		else
			dictionary.push 0

	for i in [0..maxDist] by 1
		if dists[i]?
			dictionary.push dists[i].length
		else
			dictionary.push 0

	# group codes
	gdict = []
	l = dictionary.length
	i = 0
	while i < l
		v = dictionary[i++]
		count = 1
		while i < l and dictionary[i] == v
			count++
			i++
		gdict.push {value: v, count: count}

	# encode dictionary
	edict = []
	dictFreq = (0 for i in [0..18])
	for o in gdict
		{value, count} = o
		if value > 0
			edict.push { code: value, extraBits: 0 }
			dictFreq[value]++
			count--
			while count >= 3
				ammount = if count < 6 then count else 6
				edict.push
					code: 16
					extraBits: 2
					extra: ammount - 3
				dictFreq[16]++
				count -= ammount
			while count > 0
				edict.push
					code: value
					extraBits: 0
				dictFreq[value]++
				count--
		else
			while count >= 11
				amount = if count < 138 then count else 138
				edict.push
					code: 18
					extraBits: 7
					extra: amount - 11
				dictFreq[18]++
				count -= amount
			while count >= 3
				amount = if count < 10 then count else 10
				edict.push
					code: 17
					extraBits: 3
					extra: amount - 3
				dictFreq[17]++
				count -= amount
			while count > 0
				edict.push
					code: 0
					extraBits: 0
				dictFreq[0]++
				count--

	dictCodes = Huffman.fromFrequencies(dictFreq, 7)
	order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]
	metaDictSize = order.length - 1

	while not dictCodes[order[metaDictSize]]?
		metaDictSize--
	metaDictSize

	metaDict = []
	for i in [0..metaDictSize]
		idx = order[i]
		if dictCodes[idx]?
			metaDict.push dictCodes[idx].length
		else
			metaDict.push 0

	os = new OutputStream()

	# write header
	os.writeBits(6, 3)

	# write dictionary

	os.writeBits(maxLength - 256, 5)
	os.writeBits(maxDist, 5)
	os.writeBits(metaDictSize - 3, 4)

	for symbol in metaDict
		os.writeBits(symbol, 3)

	for symbol in edict
		{code, length} = dictCodes[symbol.code]
		os.writeBits(code, length)
		if symbol.extraBits
			os.writeBits(symbol.extra, symbol.extraBits)

	# write data
	for symbol in output
		{code, length} = lengths[symbol.code]
		os.writeBits(code, length)
		if symbol.extraBits
			os.writeBits(symbol.extra, symbol.extraBits)
		if symbol.distance?
			{code, length} = dists[symbol.distance.code]
			os.writeBits(code, length)
			os.writeBits(symbol.distance.extra, symbol.distance.extraBits)
	os.getBuffer()

module.exports = encode