set_help_text rom_info\
{Prints information about the given ROM device, coming from the software
database. If no argument is given, the first found (external) ROM device is
shown.}

namespace eval rom_info {

proc tab {args} {
	set result [list]

	foreach device [machine_info device] {
		if {[dict get [machine_info device $device] "type"] eq "ROM"} {
			lappend result $device
		}
	}
	return $result
}

set_tabcompletion_proc rom_info [namespace code tab]

proc getlist_rom_info {{romdevice ""}} {
	if {$romdevice eq ""} {
		set romdevice [guess_rom_device]
		if {$romdevice eq ""} {
			error "No se encuentra dispositivo ROM (externo)"
		}
	}

	if {[catch {set device_info [machine_info device $romdevice]}]} {
		error "No existe como tal dispositivo: $romdevice"
	}

	set device_type [dict get $device_info "type"]
	if {$device_type ne "ROM"} {
		error [format "El dispositivo no es de tipo ROM, sino %s" $device_type]
	}

	set actualSHA1 [dict get $device_info "actualSHA1"]
	set originalSHA1 [dict get $device_info "originalSHA1"]
	if {[catch {set rominfo [openmsx_info software $actualSHA1]}]} {
		# try original sha1 to get more info
		if {[catch {set rominfo [openmsx_info software $originalSHA1}]} {
			return
		}
	}
	set softPatched [expr {$actualSHA1 ne $originalSHA1}]

	dict with rominfo {
		# dummy info for missing items
		foreach key [list year company] {
			if {[set $key] eq ""} {
				set $key "(informacion no disponible)"
			}
		}

		if {$original} {
			# this is an unmodified original dump
			set status [format "Volcado limpio sin modificar (confirmado por %s)" $orig_type]
		} else {
			# not original or unknown
			switch $orig_type {
				"broken" {
					set status "Volcado defectuoso (juego roto)"
				}
				"translated" {
					set status "Traducido del original"
				}
				"working" {
					set status "Modificado pero se confirma que funciona"
				}
				default {
					set status "Desconocido"
				}
			}
		}
		if {$softPatched} {
			set status "$status (parcheado por openMSX)"
		}

		return [list \
				"title"		$title \
				"year"		$year \
				"company"	$company \
				"country"	$country \
				"status"	$status \
				"remark"	$remark]
	}
}

proc rom_info {{romdevice ""}} {
	set rominfo [rom_info::getlist_rom_info $romdevice]

	if {$rominfo eq ""} {return "No hay informacion de ROM disponible..."}

	append result "Title:    [dict get $rominfo title]\n" \
				  "Year:     [dict get $rominfo year]\n" \
				  "Company:  [dict get $rominfo company]\n" \
				  "Country:  [dict get $rominfo country]\n" \
				  "Status:   [dict get $rominfo status]" \

	set remark [dict get $rominfo remark]

	if {$remark ne ""} {
		append result "\nRemark:   $remark"
	} else {
		append result "\nRemark:   Ninguna"
	}

	return $result
}

namespace export rom_info
namespace export getlist_rom_info

} ;# namespace rom_info

namespace import rom_info::*
