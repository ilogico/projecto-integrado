"use strict"

args = process.argv
if args.length < 3
	console.log "no file to decompress"
else
	fs = require 'fs'
	fs.readFile args[2], (e, d)->
		if e
			console.log "error opening file"
			throw e
		compressedSize = d.length
		try
			encoded = require('./fast_decoder')(d)
			originalSize = encoded.length
			fs.writeFile args[2] + ".inflate", new Buffer(encoded), (e)->
				if e
					console.log "error writing file"
					throw e
				ratio = (compressedSize * 100 / originalSize).toFixed(2) + '%'
				console.log "Finished! Compression ratio: " + ratio
		catch error
			console.log "error decompressing data:", error.toString()
			throw error