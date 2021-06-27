#
# Makefile for CompOrg Project
#

#
# Location of the processing programs
#
RASM  = /home/fac/wrc/bin/rasm
RLINK = /home/fac/wrc/bin/rlink
RSIM  = /home/fac/wrc/bin/rsim

#
# Suffixes to be used or created
#
.SUFFIXES:      .asm .obj .lst .out

#
# Object files to be created
#
OBJECTS = tents.obj # subject to change/additions

#
# Transformation rule: .asm into .obj
#
.asm.obj:
	$(RASM) -l $*.asm > $*.lst

#
# Transformation rule: .obj into .out
#
.obj.out:
	$(RLINK) -o $*.out $*.obj

#
# Main target
#
tents.out:       $(OBJECTS)
	$(RLINK) -m -o tents.out $(OBJECTS) > tree.map

run:	tents.out
	$(RSIM) tents.out

