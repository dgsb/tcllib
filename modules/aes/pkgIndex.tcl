if {![package vsatisfies [package provide Tcl] 8.2]} {return}
package ifneeded aes 1.0.0 [list source [file join $dir aes.tcl]]
