zlib = require 'zlib'
fs = require 'fs'

fs.readFile './crime-do-padre-amaro.txt', (err, data)->
	console.log 'size', data.length
	deflater = zlib.createDeflateRaw()
	for b in data
		deflater.write String.fromCharCode(b)
	undefined