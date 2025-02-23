\version "2.20.0"
#(set-global-staff-size 20)

% un-comment the next line to remove Lilypond tagline:
% \header { tagline="" }

% comment out the next line if you're debugging jianpu-ly
% (but best leave it un-commented in production, since
% the point-and-click locations won't go to the user input)
\pointAndClickOff

\paper {
  print-all-headers = ##t %% allow per-score headers

  % un-comment the next line for A5:
  % #(set-default-paper-size "a5" )

  % un-comment the next line for no page numbers:
  % print-page-number = ##f

  % un-comment the next 3 lines for a binding edge:
  % two-sided = ##t
  % inner-margin = 20\mm
  % outer-margin = 10\mm

  % un-comment the next line for a more space-saving header layout:
  % scoreTitleMarkup = \markup { \center-column { \fill-line { \magnify #1.5 { \bold { \fromproperty #'header:dedication } } \magnify #1.5 { \bold { \fromproperty #'header:title } } \fromproperty #'header:composer } \fill-line { \fromproperty #'header:instrument \fromproperty #'header:subtitle \smaller{\fromproperty #'header:subsubtitle } } } }

  % Might need to enforce a minimum spacing between systems, especially if lyrics are below the last staff in a system and numbers are on the top of the next
  system-system-spacing = #'((basic-distance . 7) (padding . 5) (stretchability . 1e7))
  score-markup-spacing = #'((basic-distance . 9) (padding . 5) (stretchability . 1e7))
  score-system-spacing = #'((basic-distance . 9) (padding . 5) (stretchability . 1e7))
  markup-system-spacing = #'((basic-distance . 2) (padding . 2) (stretchability . 0))
}

%% 2-dot and 3-dot articulations
#(append! default-script-alist
   (list
    `(two-dots
       . (
           (stencil . ,ly:text-interface::print)
           (text . ,#{ \markup \override #'(font-encoding . latin1) \center-align \bold ":" #})
           (padding . 0.20)
           (avoid-slur . inside)
           (direction . ,UP)))))
#(append! default-script-alist
   (list
    `(three-dots
       . (
           (stencil . ,ly:text-interface::print)
           (text . ,#{ \markup \override #'(font-encoding . latin1) \center-align \bold "⋮" #})
           (padding . 0.30)
           (avoid-slur . inside)
           (direction . ,UP)))))
"two-dots" =
#(make-articulation 'two-dots)

"three-dots" =
#(make-articulation 'three-dots)

\layout {
  \context {
    \Score
    scriptDefinitions = #default-script-alist
  }
}

note-mod =
#(define-music-function
     (text note)
     (markup? ly:music?)
   #{
     \tweak NoteHead.stencil #ly:text-interface::print
     \tweak NoteHead.text
        \markup \lower #0.5 \sans \bold #text
     \tweak Rest.stencil #ly:text-interface::print
     \tweak Rest.text
        \markup \lower #0.5 \sans \bold #text
     #note
   #})
#(define (flip-beams grob)
   (ly:grob-set-property!
    grob 'stencil
    (ly:stencil-translate
     (let* ((stl (ly:grob-property grob 'stencil))
            (centered-stl (ly:stencil-aligned-to stl Y DOWN)))
       (ly:stencil-translate-axis
        (ly:stencil-scale centered-stl 1 -1)
        (* (- (car (ly:stencil-extent stl Y)) (car (ly:stencil-extent centered-stl Y))) 0) Y))
     (cons 0 -0.8))))

%=======================================================
#(define-event-class 'jianpu-grace-curve-event 'span-event)

#(define (add-grob-definition grob-name grob-entry)
   (set! all-grob-descriptions
         (cons ((@@ (lily) completize-grob-entry)
                (cons grob-name grob-entry))
               all-grob-descriptions)))

#(define (jianpu-grace-curve-stencil grob)
   (let* ((elts (ly:grob-object grob 'elements))
          (refp-X (ly:grob-common-refpoint-of-array grob elts X))
          (X-ext (ly:relative-group-extent elts refp-X X))
          (refp-Y (ly:grob-common-refpoint-of-array grob elts Y))
          (Y-ext (ly:relative-group-extent elts refp-Y Y))
          (direction (ly:grob-property grob 'direction RIGHT))
          (x-start (* 0.5 (+ (car X-ext) (cdr X-ext))))
          (y-start (+ (car Y-ext) 0.32))
          (x-start2 (if (eq? direction RIGHT)(+ x-start 0.5)(- x-start 0.5)))
          (x-end (if (eq? direction RIGHT)(+ (cdr X-ext) 0.2)(- (car X-ext) 0.2)))
          (y-end (- y-start 0.5))
          (stil (ly:make-stencil `(path 0.1
                                        (moveto ,x-start ,y-start
                                         curveto ,x-start ,y-end ,x-start ,y-end ,x-start2 ,y-end
                                         lineto ,x-end ,y-end))
                                  X-ext
                                  Y-ext))
          (offset (ly:grob-relative-coordinate grob refp-X X)))
     (ly:stencil-translate-axis stil (- offset) X)))

#(add-grob-definition
  'JianpuGraceCurve
  `(
     (stencil . ,jianpu-grace-curve-stencil)
     (meta . ((class . Spanner)
              (interfaces . ())))))

#(define jianpu-grace-curve-types
   '(
      (JianpuGraceCurveEvent
       . ((description . "Used to signal where curve encompassing music start and stop.")
          (types . (general-music jianpu-grace-curve-event span-event event))
          ))
      ))

#(set!
  jianpu-grace-curve-types
  (map (lambda (x)
         (set-object-property! (car x)
           'music-description
           (cdr (assq 'description (cdr x))))
         (let ((lst (cdr x)))
           (set! lst (assoc-set! lst 'name (car x)))
           (set! lst (assq-remove! lst 'description))
           (hashq-set! music-name-to-property-table (car x) lst)
           (cons (car x) lst)))
    jianpu-grace-curve-types))

#(set! music-descriptions
       (append jianpu-grace-curve-types music-descriptions))

#(set! music-descriptions
       (sort music-descriptions alist<?))


#(define (add-bound-item spanner item)
   (if (null? (ly:spanner-bound spanner LEFT))
       (ly:spanner-set-bound! spanner LEFT item)
       (ly:spanner-set-bound! spanner RIGHT item)))

jianpuGraceCurveEngraver =
#(lambda (context)
   (let ((span '())
         (finished '())
         (current-event '())
         (event-start '())
         (event-stop '()))
     `(
       (listeners
        (jianpu-grace-curve-event .
          ,(lambda (engraver event)
             (if (= START (ly:event-property event 'span-direction))
                 (set! event-start event)
                 (set! event-stop event)))))

       (acknowledgers
        (note-column-interface .
          ,(lambda (engraver grob source-engraver)
             (if (ly:spanner? span)
                 (begin
                  (ly:pointer-group-interface::add-grob span 'elements grob)
                  (add-bound-item span grob)))
             (if (ly:spanner? finished)
                 (begin
                  (ly:pointer-group-interface::add-grob finished 'elements grob)
                  (add-bound-item finished grob)))))
        (inline-accidental-interface .
          ,(lambda (engraver grob source-engraver)
             (if (ly:spanner? span)
                 (begin
                  (ly:pointer-group-interface::add-grob span 'elements grob)))
             (if (ly:spanner? finished)
                 (ly:pointer-group-interface::add-grob finished 'elements grob))))
        (script-interface .
          ,(lambda (engraver grob source-engraver)
             (if (ly:spanner? span)
                 (begin
                  (ly:pointer-group-interface::add-grob span 'elements grob)))
             (if (ly:spanner? finished)
                 (ly:pointer-group-interface::add-grob finished 'elements grob)))))
       
       (process-music .
         ,(lambda (trans)
            (if (ly:stream-event? event-stop)
                (if (null? span)
                    (ly:warning "No start to this curve.")
                    (begin
                     (set! finished span)
                     (ly:engraver-announce-end-grob trans finished event-start)
                     (set! span '())
                     (set! event-stop '()))))
            (if (ly:stream-event? event-start)
                (begin
                 (set! span (ly:engraver-make-grob trans 'JianpuGraceCurve event-start))
                 (set! event-start '())))))
       
       (stop-translation-timestep .
         ,(lambda (trans)
            (if (and (ly:spanner? span)
                     (null? (ly:spanner-bound span LEFT)))
                (ly:spanner-set-bound! span LEFT
                  (ly:context-property context 'currentMusicalColumn)))
            (if (ly:spanner? finished)
                (begin
                 (if (null? (ly:spanner-bound finished RIGHT))
                     (ly:spanner-set-bound! finished RIGHT
                       (ly:context-property context 'currentMusicalColumn)))
                 (set! finished '())
                 (set! event-start '())
                 (set! event-stop '())))))
       
       (finalize
        (lambda (trans)
          (if (ly:spanner? finished)
              (begin
               (if (null? (ly:spanner-bound finished RIGHT))
                   (set! (ly:spanner-bound finished RIGHT)
                         (ly:context-property context 'currentMusicalColumn)))
               (set! finished '())))))
       )))

jianpuGraceCurveStart =
#(make-span-event 'JianpuGraceCurveEvent START)

jianpuGraceCurveEnd =
#(make-span-event 'JianpuGraceCurveEvent STOP)
%===========================================================

%{ The jianpu-ly input was:
%text format: 838.3
title=痴情冢
subtitle=电视剧《新天龙八部》主题曲
poet=抄谱:ye838.4
composer= 林海 曲 沈永峰词
arranger= 成鎂甄课件

1=F 4/4
4=84
%WithStaff
NoIndent


LP:\override Score.BarNumber.stencil = #(make-stencil-boxer 0.1 0.25 ly:text-interface::print)
:LP
 6 q1' 3'q 2' 1'q 7q | 6q. 7s 6q 5q 3 3q 5q | 6 1' 7 5 | 6 - - - ~ | 6 - - - 
LP: \bar "||" 
:LP
 \break R{ 6, 1q ( 3q ) 2 1q ( 7,q ) | 6,q. ( 7,s ) 6,q ( 5,q ) 3, - | 0q 6,q 7,q 1q 7, 6,q 5,q ~ | 5,q 6,q ~ 6, - - \break 6, 1q ( 3q ) 2 1q ( 2q ) | 3 5q ( 3q ) 3 - | 0q 6,q 7,q 1q 7, 6,q 5,q ~ | 5,q 6,q ~ 6, - - | \break 6 5q ( 6q ) 3 2q ( 1q ) | 2 2q ( 3q ) 6, - | 2q 3q 1q 6,q 2 3q ( 5q ) | 3 - - - | \break 6 5q ( 6q ) 3 2q ( 1q )  2 2q ( 3q ) 6, -  2q 3q 1q 6,q 5, 3,q ( 5,q ) }  A{ 6, - - 0  0 - - - | 6, - 0 -  6 5q ( 6q ) 3 2q ( 1q )  2 2q ( 3q ) 6, - 2q 3q 1q 6,q 2 3q ( 5q )  3 - - - }  \break 6 5q ( 6q ) 3 2q ( 1q )  2 2q ( 3q ) 6, -  2q 3q 1q 6,q 5, 3,q ( 5,q )  5,q 6,q ~ 6, - - |

H: \repeat unfold 17 { \skip 1 } 1. 眼里柔情都是你，爱里落花水漂零， 梦里牵手都是你，命里纠结无处醒。 今生君恩还不尽，愿有来生化春泥， 雁过无痕风有情，生死两忘江湖里。

H: \repeat unfold 17 { \skip 1 } 2. 人前笑语花相映，人后哭泣倩人听， 偏生爱的都是你，谁错谁对本无凭。 今生君恩还不尽，愿有来生化春泥， 雁过无痕风有情，生死两忘江湖  \skip 1 里。 今生君恩还不尽，愿有来生化春泥， 雁过无痕风有情，生死两忘江湖里。
%}


\score {
<< \override Score.BarNumber.break-visibility = #center-visible
\override Score.BarNumber.Y-offset = -1
\set Score.barNumberVisibility = #(every-nth-bar-number-visible 5)

%% === BEGIN JIANPU STAFF ===
    \new RhythmicStaff \with {
    \consists "Accidental_engraver" 
    \consists \jianpuGraceCurveEngraver
    % Get rid of the stave but not the barlines:
    \override StaffSymbol.line-count = #0 % tested in 2.15.40, 2.16.2, 2.18.0, 2.18.2, 2.20.0 and 2.22.2
    \override BarLine.bar-extent = #'(-2 . 2) % LilyPond 2.18: please make barlines as high as the time signature even though we're on a RhythmicStaff (2.16 and 2.15 don't need this although its presence doesn't hurt; Issue 3685 seems to indicate they'll fix it post-2.18)
    $(add-grace-property 'Voice 'Stem 'direction DOWN)
    $(add-grace-property 'Voice 'Slur 'direction UP)
    $(add-grace-property 'Voice 'Stem 'length-fraction 0.5)
    $(add-grace-property 'Voice 'Beam 'beam-thickness 0.1)
    $(add-grace-property 'Voice 'Beam 'length-fraction 0.3)
    $(add-grace-property 'Voice 'Beam 'after-line-breaking flip-beams)
    $(add-grace-property 'Voice 'Beam 'Y-offset 2.5)
    $(add-grace-property 'Voice 'NoteHead 'Y-offset 2.5)
    }
    { \new Voice="Y" {
    \override Beam.transparent = ##f
    \override Stem.direction = #DOWN
    \override Tie.staff-position = #2.5
    \tupletUp
    \tieUp
    \override Stem.length-fraction = #0.5
    \override Beam.beam-thickness = #0.1
    \override Beam.length-fraction = #0.5
    \override Beam.after-line-breaking = #flip-beams
    \override Voice.Rest.style = #'neomensural % this size tends to line up better (we'll override the appearance anyway)
    \override Accidental.font-size = #-4
    \override TupletBracket.bracket-visibility = ##t
\set Voice.chordChanges = ##t %% 2.19 bug workaround

    \override Staff.TimeSignature.style = #'numbered
    \override Staff.Stem.transparent = ##t
     \mark \markup{1=F} \time 4/4 \tempo 4=84 \override Score.BarNumber.stencil = #(make-stencil-boxer 0.1 0.25 ly:text-interface::print)
 \note-mod "6" a4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8^.[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8^.]
 \note-mod "2" d4^. \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8^.[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "7" b8]
| | %{ bar 2: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "6" a8.[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "7" b16]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "6" a8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8]
 \note-mod "3" e4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8]
| | %{ bar 3: %}
 \note-mod "6" a4
 \note-mod "1" c4^.  \note-mod "7" b4  \note-mod "5" g4 | \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 4: %}
 \note-mod "6" a4
\=JianpuTie(  ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" a4
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" a4
 ~  \note-mod "–" a4 | \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 5: %}
 \note-mod "6" a4
 ~ \=JianpuTie) \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" a4
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" a4
 ~  \note-mod "–" a4  \bar "||"
\break \repeat volta 2 { | %{ bar 6: %}
 \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
)  \note-mod "2" d4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "7" b8-\tweak #'X-offset #0.6 _. ]
) | | %{ bar 7: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "6" a8.-\tweak #'X-offset #0.6 _. [
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #2
 \note-mod "7" b16-\tweak #'X-offset #0.6 _. ]
) \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. [
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8-\tweak #'X-offset #0.6 _. ]
) \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "3" e4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~  \note-mod "–" e4 | | %{ bar 8: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "0" r8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "7" b8-\tweak #'X-offset #0.6 _. [
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8]
 \note-mod "7" b4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. [
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8-\tweak #'X-offset #0.6 _. ]
~ | | %{ bar 9: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8-\tweak #'X-offset #0.6 _. [
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" a4
 ~  \note-mod "–" a4 \break | %{ bar 10: %}
 \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
)  \note-mod "2" d4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "2" d8]
) | | %{ bar 11: %}
 \note-mod "3" e4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
) \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "3" e4
 ~  \note-mod "–" e4 | | %{ bar 12: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "0" r8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "7" b8-\tweak #'X-offset #0.6 _. [
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8]
 \note-mod "7" b4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. [
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8-\tweak #'X-offset #0.6 _. ]
~ | | %{ bar 13: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8-\tweak #'X-offset #0.6 _. [
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" a4
 ~  \note-mod "–" a4 | \break | %{ bar 14: %}
 \note-mod "6" a4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8]
)  \note-mod "3" e4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8]
) | | %{ bar 15: %}
 \note-mod "2" d4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
) \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~  \note-mod "–" a4 | | %{ bar 16: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
 \note-mod "2" d4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8]
) | \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 17: %}
 \note-mod "3" e4
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" e4
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" e4
 ~  \note-mod "–" e4 | \break | %{ bar 18: %}
 \note-mod "6" a4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8]
)  \note-mod "3" e4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8]
) | %{ bar 19: %}
 \note-mod "2" d4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
) \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~  \note-mod "–" a4 | %{ bar 20: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
 \note-mod "5" g4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8-\tweak #'X-offset #0.6 _. [
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8-\tweak #'X-offset #0.6 _. ]
) } \alternative { { \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 21: %}
 \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" a4
 ~  \note-mod "–" a4  \note-mod "0" r4 | %{ bar 22: %}
 \note-mod "0" r4
 \note-mod "–" r4  \note-mod "–" r4  \note-mod "–" r4 } { \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 23: %}
 \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~  \note-mod "–" a4  \note-mod "0" r4  \note-mod "–" r4 | %{ bar 24: %}
 \note-mod "6" a4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8]
)  \note-mod "3" e4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8]
) | %{ bar 25: %}
 \note-mod "2" d4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
) \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~  \note-mod "–" a4 | %{ bar 26: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
 \note-mod "2" d4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8]
) \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0 | %{ bar 27: %}
 \note-mod "3" e4
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" e4
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" e4
 ~  \note-mod "–" e4 }} \break | %{ bar 28: %}
 \note-mod "6" a4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8]
)  \note-mod "3" e4 \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "1" c8]
) | %{ bar 29: %}
 \note-mod "2" d4
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
) \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~  \note-mod "–" a4 | %{ bar 30: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "2" d8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "3" e8]
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "1" c8[
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
 \note-mod "5" g4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
\set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "3" e8-\tweak #'X-offset #0.6 _. [
( \set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "5" g8-\tweak #'X-offset #0.6 _. ]
) | %{ bar 31: %} \set stemLeftBeamCount = #0
\set stemRightBeamCount = #1
 \note-mod "5" g8-\tweak #'X-offset #0.6 _. [
\set stemLeftBeamCount = #1
\set stemRightBeamCount = #1
 \note-mod "6" a8-\tweak #'X-offset #0.6 _. ]
~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "6" a4-\tweak #'Y-offset #-1.2 -\tweak #'X-offset #0.6 _. 
 ~ \once \override Tie.transparent = ##t \once \override Tie.staff-position = #0  \note-mod "–" a4
 ~  \note-mod "–" a4 | \bar "|." } }
% === END JIANPU STAFF ===

\new Lyrics = "IZ" { \lyricsto "Y" { \override LyricText.self-alignment-X = #LEFT \repeat unfold 17 { \skip 1 } 1. 眼 里 柔 情 都 是 你, 爱 里 落 花 水 漂 零,  梦 里 牵 手 都 是 你, 命 里 纠 结 无 处 醒。  今 生 君 恩 还 不 尽, 愿 有 来 生 化 春 泥,  雁 过 无 痕 风 有 情, 生 死 两 忘 江 湖 里。 } } \new Lyrics = "Ia" { \lyricsto "Y" { \override LyricText.self-alignment-X = #LEFT \repeat unfold 17 { \skip 1 } 2. 人 前 笑 语 花 相 映, 人 后 哭 泣 倩 人 听,  偏 生 爱 的 都 是 你, 谁 错 谁 对 本 无 凭。  今 生 君 恩 还 不 尽, 愿 有 来 生 化 春 泥,  雁 过 无 痕 风 有 情, 生 死 两 忘 江 湖  \skip 1  里。  今 生 君 恩 还 不 尽, 愿 有 来 生 化 春 泥,  雁 过 无 痕 风 有 情, 生 死 两 忘 江 湖 里。 } } 
>>
\header{
title="痴情冢"
subtitle="电视剧《新天龙八部》主题曲"
poet="抄谱:ye838.4"
composer="林海 曲 沈永峰词"
arranger="成鎂甄课件"
}
\layout{ indent = 0.0 
  \context {
    \Global
    \grobdescriptions #all-grob-descriptions
  }
} }
\score {
\unfoldRepeats
<< 

% === BEGIN MIDI STAFF ===
    \new Staff { \new Voice="b" { \transpose c f { \key c \major  \time 4/4 \tempo 4=84 \override Score.BarNumber.stencil = #(make-stencil-boxer 0.1 0.25 ly:text-interface::print)
a'4 c''8 e''8 d''4 c''8 b'8 | | %{ bar 2: %} a'8. b'16 a'8 g'8 e'4 e'8 g'8 | | %{ bar 3: %} a'4 c''4 b'4 g'4 | | %{ bar 4: %} a'1 ~ | | %{ bar 5: %} a'1  \bar "||"
\break \repeat volta 2 { | %{ bar 6: %} a4 c'8 ( e'8 ) d'4 c'8 ( b8 ) | | %{ bar 7: %} a8. ( b16 ) a8 ( g8 ) e2 | | %{ bar 8: %} r8 a8 b8 c'8 b4 a8 g8 ~ | | %{ bar 9: %} g8 a8 ~ a2. \break | %{ bar 10: %} a4 c'8 ( e'8 ) d'4 c'8 ( d'8 ) | | %{ bar 11: %} e'4 g'8 ( e'8 ) e'2 | | %{ bar 12: %} r8 a8 b8 c'8 b4 a8 g8 ~ | | %{ bar 13: %} g8 a8 ~ a2. | \break | %{ bar 14: %} a'4 g'8 ( a'8 ) e'4 d'8 ( c'8 ) | | %{ bar 15: %} d'4 d'8 ( e'8 ) a2 | | %{ bar 16: %} d'8 e'8 c'8 a8 d'4 e'8 ( g'8 ) | | %{ bar 17: %} e'1 | \break | %{ bar 18: %} a'4 g'8 ( a'8 ) e'4 d'8 ( c'8 ) | %{ bar 19: %} d'4 d'8 ( e'8 ) a2 | %{ bar 20: %} d'8 e'8 c'8 a8 g4 e8 ( g8 ) } \alternative { { | %{ bar 21: %} a2. r4 | %{ bar 22: %} r1 } { | %{ bar 23: %} a2 r2 | %{ bar 24: %} a'4 g'8 ( a'8 ) e'4 d'8 ( c'8 ) | %{ bar 25: %} d'4 d'8 ( e'8 ) a2 | %{ bar 26: %} d'8 e'8 c'8 a8 d'4 e'8 ( g'8 ) | %{ bar 27: %} e'1 }} \break | %{ bar 28: %} a'4 g'8 ( a'8 ) e'4 d'8 ( c'8 ) | %{ bar 29: %} d'4 d'8 ( e'8 ) a2 | %{ bar 30: %} d'8 e'8 c'8 a8 g4 e8 ( g8 ) | %{ bar 31: %} g8 a8 ~ a2. | } } }
% === END MIDI STAFF ===

>>
\header{
title="痴情冢"
subtitle="电视剧《新天龙八部》主题曲"
poet="抄谱:ye838.4"
composer="林海 曲 沈永峰词"
arranger="成鎂甄课件"
}
\midi { \context { \Score tempoWholesPerMinute = #(ly:make-moment 84 4)}} }
