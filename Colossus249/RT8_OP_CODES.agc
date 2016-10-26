### FILE="Main.annotation"
# Copyright:	Public domain.
# Filename:	RT8_OP_CODES.agc
# Purpose:	Part of the source code for Colossus, build 249.
#		It is part of the source code for the Command Module's (CM)
#		Apollo Guidance Computer (AGC), possibly for Apollo 8 and 9.
# Assembler:	yaYUL
# Reference:	Starts on p. 1498 of 1701.pdf.
# Contact:	Ron Burkey <info@sandroid.org>.
# Website:	www.ibiblio.org/apollo.
# Mod history:	08/30/04 RSB.	Adapted from corresponding Luminary131 file.
#
# The contents of the "Colossus249" files, in general, are transcribed 
# from a scanned document obtained from MIT's website,
# http://hrst.mit.edu/hrs/apollo/public/archive/1701.pdf.  Notations on this
# document read, in part:
#
#	Assemble revision 249 of AGC program Colossus by NASA
#	2021111-041.  October 28, 1968.  
#
#	This AGC program shall also be referred to as
#				Colossus 1A
#
#	Prepared by
#			Massachusetts Institute of Technology
#			75 Cambridge Parkway
#			Cambridge, Massachusetts
#	under NASA contract NAS 9-4065.
#
# Refer directly to the online document mentioned above for further information.
# Please report any errors (relative to 1701.pdf) to info@sandroid.org.
#
# In some cases, where the source code for Luminary 131 overlaps that of 
# Colossus 249, this code is instead copied from the corresponding Luminary 131
# source file, and then is proofed to incorporate any changes.

## Page 1498
		BANK	22
		SETLOC	RTBCODES
		BANK

		EBANK=	XNB
		COUNT*	$$/RTB

# LOAD TIME2, TIME1 INTO MPAC:

LOADTIME	EXTEND
		DCA	TIME2
		TCF	SLOAD2

# CONVERT THE SINGLE PRECISION 2'S COMPLEMENT NUMBER ARRIVING IN MPAC (SCALED IN HALF-REVOLUTIONS) TO A
# DP 1'S COMPLEMENT NUMBER SCALED IN REVOLUTIONS.

CDULOGIC	CCS	MPAC
		CAF	ZERO
		TCF	+3
		NOOP
		CS	HALF

		TS	MPAC +1
		CAF	ZERO
		XCH	MPAC
		EXTEND
		MP	HALF
		DAS	MPAC
		TCF	DANZIG		# MODE IS ALREADY AT DOUBLE-PRECISION
		
# READ THE PIPS INTO MPAC WITHOUT CHANGING THEM:

READPIPS	INHINT
		CA	PIPAX
		TS	MPAC
		CA	PIPAY
		TS	MPAC +3
		CA	PIPAZ
		RELINT
		TS	MPAC +5
		
		CAF	ZERO
		TS	MPAC +1
		TS	MPAC +4
		TS	MPAC +6
		
VECMODE		TCF	VMODE

# FORCE TP SIGN AGREEMENT IN MPAC:

SGNAGREE	TC	TPAGREE
## Page 1499
		TCF	DANZIG

# CONVERT THE DP 1'S COMPLEMENT ANGLE SCALED IN REVOLUTIONS TO A SINGLE PRECISION 2'S COMPLEMENT ANGLE
# SCALED IN HALF-REVOLUTIONS.

1STO2S		TC	1TO2SUB
		CAF	ZERO
		TS	MPAC +1
		TCF	NEWMODE

# DO 1STO2S ON A VECTOR OF ANGLES:

V1STO2S		TC	1TO2SUB		# ANSWER ARRIVES IN A AND MPAC.

		DXCH	MPAC +5
		DXCH	MPAC
		TC	1TO2SUB
		TS	MPAC +2

		DXCH	MPAC +3
		DXCH	MPAC
		TC	1TO2SUB
		TS	MPAC +1

		CA	MPAC +5
		TS	MPAC

TPMODE		CAF	ONE		# MODE IS TP.
		TCF	NEWMODE

# V1STO2S FOR 2 COMPONENT VECTOR. USED BY RR.

2V1STO2S	TC	1TO2SUB
		DXCH	MPAC +3
		DXCH	MPAC
		TC	1TO2SUB
		TS	L
		CA	MPAC +3
		TCF	SLOAD2

# SUBROUTINE TO DO DOUBLING AND 1'S TO 2'S CONVERSION:

1TO2SUB		DXCH	MPAC		# FINAL MPAC +1 UNSPECIFIED.
		DDOUBL
		CCS	A
		AD	ONE
		TCF	+2
		COM			# THIS WAS REVERSE OF MSU.

		TS	MPAC		# AND SKIP ON OVERFLOW.
## Page 1500
		TC	Q

		INDEX	A		# OVERFLOW UNCORRECT AND IN MSU.
		CAF	LIMITS
		ADS	MPAC
		TC	Q

## Page 1501
# SUBROUTINE TO INCREMENT CDUS

INCRCDUS	CAF	LOCTHETA
		TS	BUF		# PLACE ADRES(THETA) IN BUF.
		CAE	MPAC		# INCREMENT IN 1'S COMPL.
		TC	CDUINC
		
		INCR	BUF
		CAE	MPAC +3
		TC	CDUINC
		
		INCR	BUF
		CAE	MPAC +5
		TC	CDUINC
		
		TCF	VECMODE
		
LOCTHETA	ADRES	THETAD

# THE FOLLOWING ROUTINE INCREMENTS IN 2'S COMPLEMENT THE REGISTER WHOSE ADDRESS IS IN BUF BY THE 1'S COMPL.
# QUANTITY FOUND IN TEM2.  THIS MAY BE USED TO INCRMENT DESIRED IMU AND OPTICS CDU ANGLES OR ANY OTHER 2'S COMPL.
# (+0 UNEQUAL TO -0) QUANTITY.  MAY BE CALLED BY BANKCALL/SWCALL.

CDUINC		TS	TEM2		# 1'S COMPL. QUANT. ARRIVES IN ACC.  STORE IT
		INDEX	BUF
		CCS	0		# CHANGE 2'S COMPLE. ANGEL (IN BUF) INTO 1'S
		AD	ONE
		TCF	+4
		AD	ONE
		AD	ONE		# OVEFLOW HERE IF 2'S COMPL. IS 180 DEG.
		COM

		AD	TEM2		# SULT MOVES FROM 2ND TO 3D QUAD. (OR BACK)
		CCS	A		# BACK TO 2'S COMPL.
		AD	ONE
		TCF	+2
		COM
		TS	TEM2		# STORE 14-BIT QUANTITY WITH PRESENT SIGN
		TCF	+4
		INDEX	A		# SIGN.
		CAF	LIMITS		# FIX IT, BY ADDING IN 37777 OR 40000
		AD	TEM2

		INDEX	BUF
		TS	0		# STORE NEW ANGLE IN 2'S COMPLEMENT.
		TC	Q

## Page 1502
# RTB TO TORQUE GYROS, EXCEPT FOR THE CALL TO IMUSTALL.  ECADR OF COMMANDS ARRIVES IN X1.

PULSEIMU	INDEX	FIXLOC		# ADDRESS OF GYRO COMMANDS SHOULD BE IN X1
		CA	X1
		TC	BANKCALL
		CADR	IMUPULSE
		TCF	DANZIG

## Page 1503
# EACH ROUTINE TAKES A 3X3 MATRIX STORED IN DOUBLE PRECISION IN A FIXED AREA OF ERASABLE MEMORY AND REPLACES IT
# WITH THE TRANSPOSE MATRIX.  TRANSP1 USES LOCATIONS XNB+0,+1 THROUGH XNB+16D,+17D AND TRANSP2 USES LOCATIONS
# XNB1+0,+1 THROUGH XNB1+16D,+17D.  EACH MATRIX IS STORED BY ROWS.

XNBEB		ECADR	XNB
XNB1EB		ECADR	XNB1

		EBANK=	XNB
		
TRANSP1		CAF	XNBEB
		TS	EBANK
		DXCH	XNB +2
		DXCH	XNB +6
		DXCH	XNB +2
		
		DXCH	XNB +4
		DXCH	XNB +12D
		DXCH	XNB +4
		
		DXCH	XNB +10D
		DXCH	XNB +14D
		DXCH	XNB +10D
		TCF	DANZIG
		EBANK=	XNB1
		
TRANSP2		CAF	XNB1EB
		TS	EBANK
		DXCH	XNB1 +2
		DXCH	XNB1 +6
		DXCH	XNB1 +2
		
		DXCH	XNB1 +4
		DXCH	XNB1 +12D
		DXCH	XNB1 +4
		
		DXCH	XNB1 +10D
		DXCH	XNB1 +14D
		DXCH	XNB1 +10D
		TCF	DANZIG

## Page 1504
# THE SUBROUTINE SIGNMPAC SETS C(MPAC, MPAC +1) TO SIGN(MPAC).
# FOR THIS, ONLY THE CONTENTS OF MPAC ARE EXAMINED.  ALSO +0 YIELDS POSMAX AND -0 YIELDS NEGMAX.
#
# ENTRY MAY BE BY EITHER OF THE FOLLOWING:
#	1.	LIMIT THE SIZE OF MPAC ON INTERPRETIVE OVERFLOW:
#		ENTRY:		BOVB
#					SIGNMPAC
#	2.	GENERATE IN MPAC THE SIGNUM FUNCTION OF MPAC:
#		ENTRY:		RTB
#					SIGNMPAC
# IN EITHER CASE, RETURN IS TO TEH NEXT INTERPRETIVE INSTRUCTION IN THE CALLING SEQUENCE.

SIGNMPAC	EXTEND
		DCA	DPOSMAX
		DXCH	MPAC
		CCS	A
DPMODE		CAF	ZERO		# SETS MPAC +2 TO ZERO IN THE PROCESS
		TCF	SLOAD2 +2
		TCF	+1
		EXTEND
		DCS	DPOSMAX
		TCF	SLOAD2

# RTB OP CODE NORMUNIT IS LIKE INTERPRETIVE INSTRUCTION UNIT, EXCEPT THAT IT CAN BE DEPENDED ON NOT TO BLOW
# UP WHEN THE VECTOR BEING UNITIZED IS VERY SAMLL -- IT WILL BLOW UP WHEN ALL COMPONENT ARE ZERO.  IF NORMUNIT
# IS USED AND THE UPPER ORDER HALVES OF ALL COMPONENTS ARE ERO, THE MAGNITUDE RETURNS IN 36D WILL BE TOO LARGE
# BY A FACTOR OF 2(13) AND THE SQURED MAGNITUDE RETURNED ATE 34D WILL BE TOO BIG BY A FACTOR OF 2(26).

NORMUNX1	CAF	ONE
		TCF	NORMUNIT +1
NORMUNIT	CAF	ZERO
		AD	FIXLOC
		TS	MPAC +2
		TC	BANKCALL	# GET SIGN AGREEMENT IN ALL COMPONENTS
		CADR	VECAGREE
		CCS	MPAC
		TCF	NOSHIFT
		TCF	+2
		TCF	NOSHIFT
		CCS	MPAC +3
		TCF	NOSHIFT
		TCF	+2
		TCF	NOSHIFT
		CCS	MPAC +5
		TCF	NOSHIFT
		TCF	+2
		TCF	NOSHIFT
## Page 1505
		CA	MPAC +1		# SHIFT ALL COMPONENTS LEFT 13
		EXTEND
		MP	BIT14
		DAS	MPAC		# DAS GAINS A LITTLE ACCURACY
		CA	MPAC +4
		EXTEND
		MP	BIT14
		DAS	MPAC +3
		CA	MPAC +6
		EXTEND
		MP	BIT14
		DAS	MPAC +5
		CAF	THIRTEEN
		INDEX	MPAC +2
		TS	37D
OFFTUNIT	TC	POSTJUMP
		CADR	UNIT +1		# SKIP THE "TC VECAGREE" DONE AT UNIT

NOSHIFT		CAF	ZERO
		TCF	OFFTUNIT -2

# RTB VECSGNAG ... FORCES SIGN AGREEMENT OF VECTOR IN MPAC.

VECSGNAG	TC	BANKCALL
		CADR	VECAGREE
		TC	DANZIG

# *** END OF SATRAP  .007 ***




