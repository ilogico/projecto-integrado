(function(){
	var BitReader = function BitReader(buffer) {
		this.buffer = buffer;
		this.nextByte = 0;
		this.bits = 8;
		this.currentByte = 0;
	};

	BitReader.prototype.readBit = function() {
		if (this.bits > 7) {
			if (this.nextByte >= this.buffer.length) {
				throw new RangeError();
			}
			this.bits = 0;
			this.currentByte = this.buffer[this.nextByte++];
		}
		var ret = this.currentByte & 1;
		this.currentByte = this.currentByte >> 1;
		this.bits++;
		return ret;
	};

	BitReader.prototype.readBits = function(n) {
		var ret = 0;
		while (n-- > 0) {
			ret = ret << 1;
			ret = ret | this.readBit();
		}
		return ret;
	};

	BitReader.prototype.skipByte = function() {
		this.bits = 8;
	};

	BitReader.prototype.readByte = function() {
		if (this.nextByte >= this.buffer.length) {
			throw new RangeError();
		}
		return this.buffer[this.nextByte++];
	};

	BitReader.prototype.copyBytes = function(output, n) {
		if (this.nextByte + n > this.buffer.length) {
			throw new RangeError();
		}
		while(n-- > 0) {
			output.write(this.buffer[this.nextByte++]);
		}

	};

	//////////////////////////////////////////

	var BUFFER_SIZE = Math.pow(2, 15); //32KB
	var OutputBuffer = function OutputBuffer() {
		this.container = [];
		this.currentBuffer = new Uint8Array(BUFFER_SIZE);
		this.currentBufferLength = 0;
	};

	OutputBuffer.prototype.write = function(b) {
		if (this.currentBufferLength >= BUFFER_SIZE) {
			this.container.push(this.currentBuffer);
			this.currentBufferLength = 0;
		}
		this.currentBuffer[this.currentBufferLength++] = b;
	};

	OutputBuffer.prototype.copy = function(length, distance) {
		

	};





	module.exports.BitReader = BitReader;

})();