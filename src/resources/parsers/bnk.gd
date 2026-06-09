extends Object
class_name Bnk

# https://moddingwiki.shikadi.net/wiki/AdLib_Instrument_Bank_Format

const HEADER: Dictionary = {
	"major_version": Parser.Type.Byte,
	"minor_version": Parser.Type.Byte,
	"signature": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char],
	"number_used": Parser.Type.Word,
	"number_instruments": Parser.Type.Word,
	"names_offset": Parser.Type.DWord,
	"data_offset": Parser.Type.DWord,
	"padding": Parser.Type.QWord,
}

const NAME_SECTION: Dictionary = {
	"index": Parser.Type.Word,
	"flags": Parser.Type.Byte,
	"name": [Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char,Parser.Type.Char],
}

const INSTRUMENT_1: Dictionary = {
	"iPercussive": Parser.Type.Byte,
	"iVoiceNum": Parser.Type.Byte,
}

const INSTRUMENT_2: Dictionary = {
	"iModWaveSel": Parser.Type.Byte,
	"iCarWaveSel": Parser.Type.Byte,
}

const OPLREGS: Dictionary = {
	"ksl": Parser.Type.Byte,
	"multiple": Parser.Type.Byte,
	"feedback": Parser.Type.Byte,
	"attack": Parser.Type.Byte,
	"sustain": Parser.Type.Byte,
	"eg": Parser.Type.Byte,
	"decay": Parser.Type.Byte,
	"release_rate": Parser.Type.Byte,
	"total_level": Parser.Type.Byte,
	"am": Parser.Type.Byte,
	"vib": Parser.Type.Byte,
	"ksr": Parser.Type.Byte,
	"con": Parser.Type.Byte,
}


static func parse_filepath(filepath: String) -> Dictionary:
	var file := FileAccess.open(filepath, FileAccess.READ)
	var header: Dictionary = Parser.parse_section(file, HEADER)
	assert(file.get_position() == header.names_offset)
	
	var instruments := []
	for i in range(header.number_instruments):
		var name: Dictionary = Parser.parse_section(file, NAME_SECTION)
		instruments.append(name)
	
	assert(file.get_position() == header.data_offset)
	
	for instrument: Dictionary in instruments:
		file.seek(header.data_offset + (instrument.index * 30))
		var data: Dictionary = Parser.parse_section(file, INSTRUMENT_1)
		data["opl_modulator"] = Parser.parse_section(file, OPLREGS)
		data["opl_carrier"] = Parser.parse_section(file, OPLREGS)
		data.merge(Parser.parse_section(file, INSTRUMENT_2))
		instrument["data"] = data
	
	assert(file.get_length() == file.get_position())
	
	return {
		"header": header,
		"instruments": instruments,
	}
