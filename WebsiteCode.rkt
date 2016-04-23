#lang racket
(require net/url)
(require "tools.rkt")
(provide create-game)
(provide nostats)
(provide all-games)
(provide Goalies)
(provide most_goals)
(provide most_points)
(provide most_assists)
(provide most_wins)
(provide get-player)
(provide get-firstname)
(provide get-lastname)
(provide get-fullname)
(provide get-goals)
(provide get-number)
(provide get-assists)
(provide get-points)
(provide trending-top-3)
;I recently set up a piece of software (m.jdbjohnbrown.net) that used php _POST functions to retrieve data from a SQL table.
;I wanted to experiment and see if I could pull out the data using racket.
;The information held in the database is player stats and information for a hockey team I play for.
;I pull this information using a series of commands from net/url. Notably post-pure-port (pain in the butt figuring out how to use it. The internet was useless for once.)
;From here, I load this information into a "player object" with create-player, and access it with various selectors; as well as a display function
(define base "http://jdbjohnbrown.net/gameSync.php")
(define my-site (string->url base))
(define Header (list "Content-Type: application/x-www-form-urlencoded"))
(define target-post (string->bytes/utf-8 (format "f=tgn&id=1")))


;Code that directly contacts my website for the first segment.
;Seriously, try to figure out how to do this with no prior knowledge and the internet is NO help.
;Anyways, this uses post-pure-port to send data to a .php file which then appropriately access a SQL database.
;The information sent is "f=tgn" which tells it to return info from the FUNCTION that gets player info
;also sends "id=x" so that it knows which player to recieve. Anything over 12 will return an empty string
(define (get-player-string x)
  (define in
  (post-pure-port my-site (string->bytes/utf-8 (format (string-append "f=tgn&id=" (number->string x)))) Header) )
  (begin0
  (port->string in)
  (close-input-port in)))

;various selectors for the data held in the player objects. Used in display-player
(define (get-firstname x) (car x))
(define (get-lastname x) (cadr x))
(define (get-fullname x) (string-append (get-lastname x) ", " (get-firstname x) )) ;well actually i never use this one but i wrote it anyways
(define (get-number x) (car (third x)))
(define (get-position x) (cadr (third x)))
(define (get-goals x) (car (cadddr x)))
(define (get-assists x) (cadr (cadddr x)))
(define (get-points x) (caddr (cadddr x)))

;displays an object created with create-player
(define (display-player x)
  (define (print-player x)
    (displayln (string-append (get-firstname x) " " (get-lastname x)))
    (displayln (string-append "Number: " (get-number x)))
    (displayln (string-append "Position: " (get-position x)))
    (displayln (string-append "Goals: " (get-goals x)))
    (displayln (string-append "Assists: " (get-assists x)))
    (displayln (string-append "Points: " (get-points x)))
    )
  (if (null? x) (display "Invalid Player Object") (print-player x))
 
  )

;parses the data from get-player-string
;places the data into an list with the form (firstname lastname (number position) (goals assists points))
(define (create-player x)
  (define s (get-player-string x))
    (define (parse s)     
    (define a (string-find s #\, 0))
    (define f (substring s 0 a))
    (define l (substring s (+ a 1) (string-find s #\, (+ a 1))))
    (set! a (+(string-find s #\, (+ a 1)) 1))
    (set! a (+(string-find s #\, (+ a 1)) 1))
    (define num (substring s a  (string-find s #\, (+ a 1))))
    (set! a (+(string-find s #\, (+ a 1)) 1))
    (define pos (substring s a  (string-find s #\, (+ a 1))))
    (set! a (+(string-find s #\, (+ a 1)) 1))
    (define g (substring s a  (string-find s #\, (+ a 1))))
    (set! a (+(string-find s #\, (+ a 1)) 1))
    (define as (substring s a  (string-find s #\, (+ a 1))))
    (set! a (+(string-find s #\, (+ a 1)) 1))
    (define p (substring s a  (- (string-length s) 2)))
    (list f l (list num pos) (list g as p))
    )
  (if (equal? (substring s 0 7) ",,,,,,,") '() (parse s))
  )

;creates a list of all possible players while running create-player
(define (all-players)
  (define (loop x n)
    (define a (create-player n))
    (if (null? a) x (loop (append x (list a)) (+ n 1)))    )
(loop '() 1))

;strips the previous list of the stats provided
(define nostats (map (lambda (x) (remove-last x)) (all-players)))

;pings the website to return information about a game
(define (get-game-string x)
  (define in
  (post-pure-port my-site (string->bytes/utf-8 (format (string-append "f=ggi&id=" (number->string x)))) Header) )
  (begin0
  (port->string in)
  (close-input-port in)))

;"creates" the game by parsing the string provided by get-game-string
(define (create-game x)
  (define s (get-game-string x))
    (define (parse s)     
      (define a (string-find s #\* 0))
      (define d (substring s 0 a))
      (define opp (substring s (+ a 1) (string-find s #\* (+ a 1))))
      (set! a (+(string-find s #\* (+ a 1)) 1))
      (define for (substring s a  (string-find s #\* (+ a 1)))) 
      (set! a (+(string-find s #\* (+ a 1)) 1))      
      (define against (substring s a  (string-find s #\* (+ a 1))))     
      (set! a (+(string-find s #\* (+ a 1)) 1))
      (define goalie (substring s a  (string-find s #\* (+ a 1))))    
      (set! a (+(string-find s #\* (+ a 1)) 1))
      (define g (substring s a  (- (string-length s) 2)))
      (list d opp for against goalie g)     
    )
  (define (partial s)     
      (define a (string-find s #\* 0))
      (define d (substring s 0 a))
      (define opp (substring s (+ a 1) (string-find s #\* (+ a 1))))      
      (list d opp "0" "0" "0" "()")     
    ) 
  (if (equal? (substring s 0 5) "*****") '() (if (< (string-length (string-trim s)) 28) (partial s) (parse s)))
  )

(define (parse-game-str str)
  (define (check-c c r) (if (eq? (string->number (car-str r)) #f) c (string-append c (car-str r))))
  (define (check-r c r) (if (eq? (string->number (car-str r)) #f) r (cdr-str r)))
  (define (loop lst str state)
    (define c (car-str str))
    (define r (cdr-str str))
    (if (= (string-length str) 0) lst
        (cond
          [(not (eq? (string->number c) #f))
               (if (= state 0) (loop (append lst (list (list (string->number (check-c c r))))) (check-r c r) 1)
                   (loop (append (but-last lst) (list (append (list-last lst) (list (string->number (check-c c r))))))
                         (check-r c r) 1))]
          [(equal? c ";") (loop lst r 0)]
          [else (loop lst r state)])
    ))
  (if (equal? str "") '()
  (loop '() str 0)  )  
  
  )


;loops through create-game until it gets a null value, creating a list of all games
(define all-games ((lambda ()
  (define (loop x n)
    (define a (create-game n))
    (if (null? a) x (loop (append x  (list (append (but-last a) (list (parse-game-str (list-last a)))))) (+ n 1)))
    )
  (loop '() 1)
  )) )


;pulls goalie stats out of the all-games
;I'm actually pretty proud of this code, although it is sloppy.
;See, it iterates the entire lst once looking for the first goalie, and if the goalie doesn't match
;it places the game into an "other" list. So the original list is entirely consumed, then it moves
;to the next goalie in the other list.
(define Goalies
  ((lambda () 
     (define (getG G lst)
       
       (if (> (string->number(caddr lst))  (string->number(cadddr lst)))
           (if (= (string->number (cadddr lst)) 0)
           (list (car G) (+ (cadr G) 1) (caddr G) (cadddr G)
                 (+ (car(cddddr G)) (string->number (caddr lst)))
                 (+ (cadr (cddddr G)) (string->number (cadddr lst)))
                 (+ (caddr (cddddr G)) 1)
                 )    
           (list (car G) (+ (cadr G) 1) (caddr G) (cadddr G)
                 (+ (car(cddddr G)) (string->number (caddr lst)))
                 (+ (cadr (cddddr G)) (string->number (cadddr lst)))
                  (caddr (cddddr G))))
          (if (= (string->number (caddr lst))  (string->number (cadddr lst))) 
              (if (= (string->number (cadddr lst)) 0)
              (list (car G) (cadr G)  (caddr G) (+ (cadddr G) 1)
                 (+ (car(cddddr G)) (string->number (caddr lst)))
                 (+ (cadr (cddddr G)) (string->number (cadddr lst)))
                 (+ (caddr (cddddr G)) 1))
             (list (car G) (cadr G)  (caddr G) (+ (cadddr G) 1)
                 (+ (car(cddddr G)) (string->number (caddr lst)))
                 (+ (cadr (cddddr G)) (string->number (cadddr lst)))
                 (caddr (cddddr G)))
              )
           (list (car G) (cadr G)  (+ (caddr G) 1) (cadddr G)
                 (+ (car(cddddr G)) (string->number (caddr lst)))
                 (+ (cadr (cddddr G)) (string->number (cadddr lst)))
                  (caddr (cddddr G)))
              ))
       )
     (define (loop lst G other)
       (if (null? lst) (cons G other)
       (if (equal? (car G) (string->number(car (cddddr (car lst)))))
           (loop (cdr lst) (getG G (car lst)) other) 
           (loop (cdr lst) G (append other (list (car lst)))))
       ))1
     (define (driver lst Gs)
         (if (null? lst) Gs
             (let ([a (loop lst (list (string->number(car (cddddr (car lst)))) 0 0 0 0 0 0) '())])
             (driver (cdr a) (append Gs (list (car a))))

       )))
                 (driver all-games '())
     ))
  )




;Plainly a variable that holds the output of all-players
(define aP (all-players))






;Returns the list object of the player in aP with the most goals.
;   Ties are broken by selecting the player with the higher # of points overall
(define most_goals
  ((lambda ()
     (define (loop lst curr)
       (if (null? lst) curr
           (if (> (string->number (get-goals (car lst))) (string->number (get-goals curr)))
               (loop (cdr lst) (car lst))
               (if (= (string->number (get-goals (car lst))) (string->number (get-goals curr)))
                   (if (> (string->number (get-points (car lst))) (string->number (get-points curr)))
                       (loop (cdr lst) (car lst))
                       (loop (cdr lst) curr))
                   (loop (cdr lst) curr)))))
               
     (loop (cdr aP) (car aP))
     )))
;Returns the list object of the player in aP with the most points.
;     Ties are broken by selecting the player with the higher # of goals.
(define most_points
  ((lambda ()
     (define (loop lst curr)
       (if (null? lst) curr
           (if (> (string->number (get-points (car lst))) (string->number (get-points curr)))
               (loop (cdr lst) (car lst))
               (if (= (string->number (get-points (car lst))) (string->number (get-points curr)))
                   (if (> (string->number (get-goals (car lst))) (string->number (get-goals curr)))
                       (loop (cdr lst) (car lst))
                       (loop (cdr lst) curr))
                   (loop (cdr lst) curr)))))
               
     (loop (cdr aP) (car aP))
     )))

;Returns the list object of the player in aP with the most assists.
;Ties are broken by whichever player has the most points.
(define most_assists
  ((lambda ()
     (define (loop lst curr)
       (if (null? lst) curr
           (if (> (string->number (get-assists (car lst))) (string->number (get-assists curr)))
               (loop (cdr lst) (car lst))
               (if (= (string->number (get-assists (car lst))) (string->number (get-assists curr)))
                   (if (> (string->number (get-points (car lst))) (string->number (get-points curr)))
                       (loop (cdr lst) (car lst))
                       (loop (cdr lst) curr))
                   (loop (cdr lst) curr)))))
               
     (loop (cdr aP) (car aP))
     )))

;Parses the Goalies object to decide which goalie (not-including Goalie ID: 0 which is unplayed games)
;                                          has the most logged wins.
;                                          Ties are broken by which goalie has, more ties.
(define most_wins
  ((lambda ()
     (define (loop lst curr)
       (if (null? lst) curr
           (if (= (caar lst) 0) (loop (cdr lst) curr)
           (if (> (cadar lst) (cadr curr))
               (loop (cdr lst) (car lst))
               (if (= (cadar lst) (cadr curr))
                   (if (> (caddar lst) (caddr curr))
                       (loop (cdr lst) (car lst))
                       (loop (cdr lst) curr))
                   (loop (cdr lst) curr))))))
               
     (loop (cdr Goalies) (car Goalies))
     )))

;This code has two different ways to run, but returns the same output.
;You either pass it a player's id number (1-12) or Lastname, Firstname and it will
;return the player object out of aP
;(define (get-player x)
;  (define (str x lst)
;    (if (equal? x (get-fullname (car lst))) (car lst) (str x (cdr lst))))
;  (define (num n lst)
;    (if (= n 0) (car lst) (num (- n 1) (cdr lst))))
;  (if (number? x) (num (- x 1) aP)  (str x aP))
;  )

(define (get-player x)
  (define (str x lst)
    (if (equal? x (get-fullname (car lst))) (car lst) (str x (cdr lst))))
  (define (num n lst)
    (if (null? lst)
        '()
    (if (= n 0) (car lst) (num (- n 1) (cdr lst)))))
  (if (number? x) (num (- x 1) aP)  (str x aP))
  )

  (define (update-game x)
  (define in
  (post-pure-port my-site (string->bytes/utf-8 (format  "f=sgi&id=30&d=2016-04-11 07:29:00&opp=0&gf=&ga=&gd=%20&gid=12" )) Header) )
  (begin0
  (port->string in)
  (close-input-port in)))


(define (create-alg-list)
  (define (loop new ap)
    (if (null? ap) new
       (loop (append new (list (list  0 0))) (cdr ap))
       )
    )
  (loop '() aP)
  )

(define (trending-players-alg)
  (define (player-loop n bool alglst pntlst)    
    (if (null? pntlst)
        (if (not bool)
            (edit-num-list n alglst (list (car (get-num-list n alglst)) (+ 1 (cadr (get-num-list n alglst)))))
            alglst)
        (cond [(= (caar pntlst) n)
               (let ([a (+ (car (get-num-list n alglst)) (/ 8 (expt 2 (cadr (get-num-list n alglst)))))])                 
               (player-loop n #t 
               (edit-num-list n alglst (list a (cadr (get-num-list n alglst))))
               (cdr pntlst)))
               ]
              [(not (null? (cdar pntlst)))
               (if (= (cadar pntlst) n)
                   
                    (player-loop n #t                                 
                    (edit-num-list n alglst (list (+ (car (get-num-list n alglst)) (/ 6 (expt 2 (cadr (get-num-list n alglst))))) (cadr (get-num-list n alglst))))
                    (cdr pntlst))
                    (if (not (null? (cddar pntlst)))
                        (if (= (car (cddar pntlst)) n)
                            
                            (player-loop n #t 
                            (edit-num-list n alglst (list (+ (car (get-num-list n alglst)) (/ 6 (expt 2 (cadr (get-num-list n alglst))))) (cadr (get-num-list n alglst))))
                            (cdr pntlst))
                            (player-loop n bool alglst (cdr pntlst)))
                        (player-loop n bool alglst (cdr pntlst))
              ))]
              [else (player-loop n bool alglst (cdr pntlst))]
              )))
  (define (games-loop alglst gamelst)
    (define (eachPlayer n players alglst pntlst)
      (if (null? players) alglst
          (eachPlayer (+ n 1) (cdr players) (player-loop n #f alglst pntlst) pntlst)))
      (if (null? gamelst) alglst
          (if (null? (list-last (list-last gamelst))) (games-loop alglst (but-last gamelst))
           (games-loop (eachPlayer 1 aP alglst (list-last (list-last gamelst))) (but-last gamelst))))
    )
  (games-loop (create-alg-list) all-games)
  )

(define (trending-top-3)
  (define (loop n tp ans)
    (define a (get-num-list n tp))
    (if (null? a) ans        
          (if (> (car (get-num-list n tp)) (car (get-num-list (caddr ans) tp)))
              (if (> (car (get-num-list n tp)) (car (get-num-list (cadr ans) tp)))
                  (if (> (car (get-num-list n tp)) (car (get-num-list (car ans) tp)))
                      (loop (+ n 1) tp (list n (car ans) (cadr ans)))
                      (loop (+ n 1) tp (list (car ans) n (cadr ans))))
                  (loop (+ n 1) tp (list (car ans) (cadr ans) n)))
              (loop (+ n 1) tp ans))))    
  (define tp (trending-players-alg))
  (define ans (list 1 2 3))
  (if (> (car (get-num-list 3 tp)) (car (get-num-list 2 tp))) (set! ans (list 1 3 2)) (set! ans ans))
  (if (> (car (get-num-list (cadr ans) tp)) (car (get-num-list (car ans) tp))) (set! ans (list (cadr ans) (car ans) (caddr ans))) (set! ans ans))
  (if (> (car (get-num-list (caddr ans) tp)) (car (get-num-list (cadr ans) tp))) (set! ans (list (car ans) (caddr ans) (cadr ans))) (set! ans ans))
  (loop 4 tp ans))