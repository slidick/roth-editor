extends Object
class_name Patch


static func create_patch(a_filepath: String, b_filepath: String, patch_filepath: String) -> void:
	var a: PackedByteArray = FileAccess.get_file_as_bytes(a_filepath)
	var b: PackedByteArray = FileAccess.get_file_as_bytes(b_filepath)
	
	var data := PackedByteArray()
	var same_count: int = 0
	var diff_count: int = 0
	for i in range(min(a.size(),b.size())):
		
		if same_count > 0 and a[i] != b[i]:
			while same_count > 0x7F:
				data.append(0x80 + 0x7F)
				same_count -= 0x7F
			data.append(0x80 + same_count)
			same_count = 0
		
		if (diff_count > 0 and a[i] == b[i]) or diff_count == 0x7F:
			data.append(0x0 + diff_count)
			for j in range(diff_count, 0, -1):
				data.append(b[i-j])
			diff_count = 0
		
		if a[i] == b[i]:
			same_count += 1
		else:
			diff_count += 1
	
	# Final
	if same_count > 0:
		while same_count > 0x7F:
			data.append(0x80 + 0x7F)
			same_count -= 0x7F
		data.append(0x80 + same_count)
		same_count = 0
	
	elif diff_count > 0:
		data.append(0x0 + diff_count)
		for j in range(diff_count, 0, -1):
			data.append(b[min(a.size(),b.size())-j])
		diff_count = 0
	
	# Append remainder
	if b.size() > a.size():
		var full: int = floori((b.size() - a.size()) / float(0x7F))
		var mod: int = (b.size() - a.size()) % 0x7F
		var pos: int = a.size()
		if full > 0:
			pos += 0x7F
			for i in range(full):
				data.append(0x0 + 0x7F)
				for j in range(0x7F, 0, -1):
					data.append(b[pos-j])
				pos += 0x7F
			pos -= 0x7F
		pos += mod
		data.append(0x0 + mod)
		for j in range(mod, 0, -1):
			data.append(b[pos-j])
	
	elif a.size() > b.size():
		pass
	
	
	var patch_file := FileAccess.open(patch_filepath, FileAccess.WRITE)
	patch_file.store_buffer(data)
	patch_file.close()


static func apply_patch(in_filepath: String, patch_filepath: String, out_filepath: String, test_filepath: String = "") -> Variant:
	var in_file: PackedByteArray = FileAccess.get_file_as_bytes(in_filepath)
	var patch_file: PackedByteArray = FileAccess.get_file_as_bytes(patch_filepath)
	
	var in_pos: int = 0
	var patch_pos: int = 0
	while patch_pos < patch_file.size():
		var byte: int = patch_file[patch_pos]
		patch_pos += 1
		if byte & 0x80:
			var skip: int = byte - 0x80
			in_pos += skip
		else:
			for i in range(byte):
				if in_pos >= in_file.size():
					in_file.append(patch_file[patch_pos])
				else:
					in_file[in_pos] = patch_file[patch_pos]
				in_pos += 1
				patch_pos += 1
	
	if in_pos < in_file.size():
		in_file.resize(in_pos)
	
	var file := FileAccess.open(out_filepath, FileAccess.WRITE)
	file.store_buffer(in_file)
	file.close()
	
	if not test_filepath.is_empty():
		Console.print("Testing patch...")
		if FileAccess.get_md5(test_filepath) == FileAccess.get_md5(out_filepath):
			Console.print("passed.\n")
			return true
		else:
			Console.print("failed.\n")
			return false
	return null


static func create_patch_from_folders(a_directory: String, b_directory: String, out_directory: String, erase_testfile: bool = true) -> void:
	var start_time: float = Time.get_ticks_msec()
	var a_dir := DirAccess.get_files_at(a_directory)
	var b_dir := DirAccess.get_files_at(b_directory)
	
	var found: bool = false
	for filename: String in a_dir:
		if filename not in b_dir:
			Console.print("Found %s in A not in B" % filename)
			found = true
	for filename: String in b_dir:
		if filename not in a_dir:
			Console.print("Found %s in B not in A" % filename)
			found = true
	
	if found:
		return
	
	DirAccess.make_dir_recursive_absolute(out_directory.path_join("PATCHES"))
	DirAccess.make_dir_recursive_absolute(out_directory.path_join("TEST"))
	
	for filename: String in a_dir:
		var a_filepath: String = a_directory.path_join(filename)
		var b_filepath: String = b_directory.path_join(filename)
		if FileAccess.get_md5(a_filepath) == FileAccess.get_md5(b_filepath):
			pass
			#Console.print("%s files same." % filename)
		else:
			Console.print("%s:\nCreating patch..." % filename)
			var patch_filepath: String = out_directory.path_join("PATCHES").path_join(filename.replace(".", "_")+".PATCH")
			var out_filepath: String = out_directory.path_join("TEST").path_join(filename)
			create_patch(a_filepath, b_filepath, patch_filepath)
			Console.print("Applying patch...")
			if not apply_patch(a_filepath, patch_filepath, out_filepath, b_filepath):
				return
			if erase_testfile:
				DirAccess.remove_absolute(out_filepath)
	
	Console.print("Zipping...")
	var zip := ZIPPacker.new()
	var err: Error = zip.open(out_directory.path_join("US_PATCH.ZIP"))
	zip.compression_level = ZIPPacker.COMPRESSION_BEST
	if err == OK:
		for filename: String in DirAccess.get_files_at(out_directory.path_join("PATCHES")):
			print(filename)
			var patch: PackedByteArray = FileAccess.get_file_as_bytes(out_directory.path_join("PATCHES").path_join(filename))
			zip.start_file(filename, 420, Time.get_unix_time_from_datetime_string("2026-07-01"))
			zip.write_file(patch)
			zip.close_file()
		zip.close()
	
	Utility.remove_dir_recursive(out_directory.path_join("PATCHES"))
	Utility.remove_dir_recursive(out_directory.path_join("TEST"))
	
	Console.print("Time: %.1fs" % ((Time.get_ticks_msec()-start_time)/1000.0))
