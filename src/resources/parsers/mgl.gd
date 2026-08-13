extends Object
class_name MGL
# https://github.com/radishengine/denormalize

var bytes: PackedByteArray = []
var buf: PackedByteArray = []
var in_i: int = 0
var out_i: int = 0


static func convert_to_das(das_info: Dictionary) -> bool:
	var data: PackedByteArray = decode_mgl(das_info)
	if not data.is_empty():
		var file := FileAccess.open(das_info.filepath, FileAccess.WRITE)
		file.store_buffer(data)
		file.close()
		return true
	return false


static func decode_mgl(das_info: Dictionary) -> PackedByteArray:
	if not FileAccess.file_exists(das_info.filepath_mgl):
		return []
	var mgl := new(FileAccess.get_file_as_bytes(das_info.filepath_mgl))
	return mgl.decode()


func _init(p_bytes: PackedByteArray) -> void:
	bytes = p_bytes


func ensure(out: int) -> void:
	var new_size: int = buf.size()
	while (out_i + out) > new_size:
		new_size *= 2
	if new_size == buf.size():
		return
	buf.resize(new_size)


func all_zero(p_bytes: PackedByteArray, i: int, j: int) -> bool:
	while i < j:
		if p_bytes[i] != 0:
			return false
		i += 1
	return true


func decode() -> PackedByteArray:
	buf.resize(roundi(pow(2, ceil(log(bytes.size() + 1)/log(2)))))
	while in_i < buf.size():
		var b: int = bytes[in_i]
		in_i += 1
		var offset: int = 0
		var length: int = 0
		var reps: int = 0
		
		if ((b >> 4) == 0
			or (b >> 4) == 0x1
			or (b >> 4) == 0x2
			or (b >> 4) == 0x3
		):
			#Console.print("0x0-3")
			#Console.print(b)
			if b == 0:
				#print("DONE")
				break
			length = b
			if ((in_i + length) > bytes.size()):
				print('invalid MGL: not enough input')
				return []
			ensure(length)
			#Console.print("%d, %d" % [in_i, out_i])
			if (not all_zero(bytes, in_i, in_i + length)):
				for i in range(length):
					buf[out_i] = bytes[in_i]
					out_i += 1
					in_i += 1
			else:
				out_i += length
				in_i += length
			
			continue
		
		elif (b >> 4) == 0x4:
			#Console.print("0x4")
			length = 3 + (b & 0xF)
			if (out_i < 2):
				print('invalid MGL: 2-byte pattern too early')
				return []
			ensure(length)
			var state: int = buf[out_i-1]
			var inc: int = state - buf[out_i-2]
			if (state == 0 && inc == 0):
				out_i += length
			else:
				while true:
					state += inc
					buf[out_i] = state 
					out_i += 1
					length -= 1
					if length == 0:
						break
			continue
		elif (b >> 4) == 0x5:
			#Console.print("0x5")
			length = 2 + (b & 0xF)
			if (out_i < 4):
				print('invalid MGL: 2-word pattern too early')
				return []
			ensure(length*2)
			#var dv = new DataView(buf.buffer, buf.byteOffset, buf.byteLength)
			var state: int = buf.decode_u16(out_i-2)
			var inc: int = state - buf.decode_u16(out_i-4)
			if (state == 0 && inc == 0):
				out_i += 2 * length
			else:
				while true:
					buf.encode_u16(out_i, buf.decode_u16(out_i - 2) + inc)
					#dv.setUint16(out_i, dv.getUint16(out_i - 2, true) + inc, true);
					out_i += 2
					length -= 1
					if length == 0:
						break
			continue
		
		elif (b >> 4) == 0x6:
			#Console.print("0x6")
			offset = 1
			length = 1
			reps = 3 + (b & 0xF)
		
		elif (b >> 4) == 0x7:
			#Console.print("0x7")
			offset = 2
			length = 2
			reps = 2 + (b & 0xF)
		
		elif ((b >> 4) == 0x8
			or (b >> 4) == 0x9
			or (b >> 4) == 0xA
			or (b >> 4) == 0xB
		):
			#Console.print("0x8-B")
			offset = 3 + (b & 0x3F)
			length = 3
			reps = 1
		
		elif ((b >> 4) == 0xC
			or (b >> 4) == 0xD
		):
			#Console.print("0xC-D")
			offset = 3 + (((b & 3) << 8) | bytes[in_i])
			in_i += 1
			length = 4 + ((b >> 2) & 7)
			reps = 1
		
		elif ((b >> 4) == 0xE
			or (b >> 4) == 0xF
		):
			#Console.print("0xE-F")
			offset = 3 + (((b & 0x1F) << 8) | bytes[in_i])
			in_i += 1
			length = 5 + bytes[in_i]
			in_i += 1
			reps = 1
		
		ensure(length * reps)
		if (offset > out_i):
			print('invalid MGL: too far back')
			return []
		offset = out_i - offset
		if ((offset+length) > out_i):
			if (all_zero(buf, offset, out_i)):
				out_i += length * reps
				continue
			var copy: PackedByteArray = buf.slice(offset, out_i)
			while true:
				var repLength: int = length
				while true:
				#while repLength >= copy.size():
					for byte: int in copy:
						buf.set(out_i, byte)
						out_i += 1
					#out_i += copy.size()
					repLength -= copy.size()
					if repLength < copy.size():
						break
				
				if (repLength > 0):
					for byte: int in copy.slice(0, repLength):
						buf.set(out_i, byte)
						out_i += 1
					#out_i += repLength
				reps -= 1
				if reps == 0:
					break
		else:
			if (all_zero(buf, offset, offset + length)):
				out_i += length * reps
				continue
			var copy: PackedByteArray = buf.slice(offset, offset + length)
			while true:
				for byte: int in copy:
					buf.set(out_i, byte)
					out_i += 1
				reps -= 1
				if reps == 0:
					break
				#out_i += length
		
		#print(out_i)
	return buf.slice(0, out_i)
