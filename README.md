# MAT-240B-2011-HRTF

MAT 240B - 2011/03/18 - Karl Yerkes

this code was written in an effort to prototype an online, realtime
hrtf-based binaural spatializer.  the evetual goal is to run this
spatializer on an iPhone as part of the AlloScope project, started
by Danny Bazo and Karl Yerkes, in the Winter of 2010.

this code uses a weighted sum of the 4 HRTFs that are nearest to the
given elevation and azimuth.

`IRC_1022_C_HRIR.mat` was downloaded from IRCAM's [HRTF database](http://recherche.ircam.fr/equipes/salles/listen/download.html).
