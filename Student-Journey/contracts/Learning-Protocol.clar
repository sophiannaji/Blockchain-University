;; Learning Achievement Tracking Smart Contract
;; A comprehensive system for tracking educational achievements, courses, and certifications

;; CONSTANTS AND ERROR CODES

;; Error codes for better debugging
(define-constant ERR_UNAUTHORIZED (err u1000))
(define-constant ERR_NOT_FOUND (err u1001))
(define-constant ERR_ALREADY_EXISTS (err u1002))
(define-constant ERR_INVALID_INPUT (err u1003))
(define-constant ERR_INSUFFICIENT_BALANCE (err u1004))
(define-constant ERR_COURSE_NOT_ACTIVE (err u1005))
(define-constant ERR_PREREQUISITE_NOT_MET (err u1006))
(define-constant ERR_ACHIEVEMENT_LOCKED (err u1007))
(define-constant ERR_INVALID_SCORE (err u1008))
(define-constant ERR_ENROLLMENT_CLOSED (err u1009))

;; Contract constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant MAX_COURSE_NAME_LENGTH u100)
(define-constant MAX_DESCRIPTION_LENGTH u500)
(define-constant MIN_PASSING_SCORE u60)
(define-constant MAX_SCORE u100)

;; DATA VARIABLES

;; Global counters
(define-data-var course-id-counter uint u0)
(define-data-var achievement-id-counter uint u0)
(define-data-var certificate-id-counter uint u0)

;; Contract configuration
(define-data-var contract-paused bool false)
(define-data-var enrollment-fee uint u1000000) ;; 1 STX in microSTX

;; DATA MAPS

;; Course management
(define-map courses
  { course-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    instructor: principal,
    credits: uint,
    difficulty-level: (string-ascii 20),
    prerequisites: (list 10 uint),
    max-enrollment: uint,
    current-enrollment: uint,
    is-active: bool,
    created-at: uint,
    updated-at: uint
  }
)

;; Student enrollments
(define-map enrollments
  { student: principal, course-id: uint }
  {
    enrolled-at: uint,
    progress: uint, ;; Percentage (0-100)
    status: (string-ascii 20), ;; "enrolled", "in-progress", "completed", "dropped"
    final-score: (optional uint),
    completion-date: (optional uint)
  }
)

;; Achievement definitions
(define-map achievements
  { achievement-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    points: uint,
    requirements: (string-ascii 300),
    is-active: bool,
    created-by: principal,
    created-at: uint
  }
)

;; Student achievements (earned)
(define-map student-achievements
  { student: principal, achievement-id: uint }
  {
    earned-at: uint,
    verified-by: principal,
    score: uint,
    notes: (optional (string-ascii 200))
  }
)

;; Certificates issued
(define-map certificates
  { certificate-id: uint }
  {
    student: principal,
    course-id: uint,
    achievement-id: (optional uint),
    issued-by: principal,
    issued-at: uint,
    grade: (string-ascii 10),
    final-score: uint,
    verification-hash: (string-ascii 64),
    is-revoked: bool
  }
)

;; Student profiles
(define-map student-profiles
  { student: principal }
  {
    total-credits: uint,
    total-achievements: uint,
    total-points: uint,
    level: uint,
    join-date: uint,
    last-activity: uint,
    reputation-score: uint
  }
)

;; Instructor profiles
(define-map instructor-profiles
  { instructor: principal }
  {
    total-courses: uint,
    total-students: uint,
    average-rating: uint,
    join-date: uint,
    is-verified: bool,
    specializations: (list 5 (string-ascii 50))
  }
)

;; Course reviews and ratings
(define-map course-reviews
  { student: principal, course-id: uint }
  {
    rating: uint, ;; 1-5 stars
    review: (optional (string-ascii 300)),
    submitted-at: uint
  }
)

;; AUTHORIZATION FUNCTIONS

(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (is-course-instructor (course-id uint))
  (match (map-get? courses { course-id: course-id })
    course-data (is-eq tx-sender (get instructor course-data))
    false
  )
)

(define-private (is-contract-active)
  (not (var-get contract-paused))
)

;; INPUT VALIDATION FUNCTIONS

(define-private (is-valid-string-input (input (string-ascii 500)))
  (and (> (len input) u0) (<= (len input) u500))
)

(define-private (is-valid-short-string (input (string-ascii 100)))
  (and (> (len input) u0) (<= (len input) u100))
)

(define-private (is-valid-category (input (string-ascii 50)))
  (and (> (len input) u0) (<= (len input) u50))
)

(define-private (is-valid-difficulty (input (string-ascii 20)))
  (and (> (len input) u0) (<= (len input) u20))
)

(define-private (is-valid-requirements (input (string-ascii 300)))
  (and (> (len input) u0) (<= (len input) u300))
)

(define-private (is-valid-grade (input (string-ascii 10)))
  (and (> (len input) u0) (<= (len input) u10))
)

(define-private (is-valid-course-id (course-id uint))
  (and (> course-id u0) (<= course-id (var-get course-id-counter)))
)

(define-private (is-valid-achievement-id (achievement-id uint))
  (and (> achievement-id u0) (<= achievement-id (var-get achievement-id-counter)))
)

(define-private (is-valid-certificate-id (certificate-id uint))
  (and (> certificate-id u0) (<= certificate-id (var-get certificate-id-counter)))
)

(define-private (is-valid-rating (rating uint))
  (and (>= rating u1) (<= rating u5))
)

(define-private (is-valid-progress (progress uint))
  (<= progress u100)
)

(define-private (is-valid-fee (fee uint))
  (>= fee u0)
)

(define-private (is-valid-principal (input principal))
  (not (is-eq input 'ST000000000000000000002AMW42H))
)

(define-private (is-valid-prerequisites (prereqs (list 10 uint)))
  (<= (len prereqs) u10)
)

(define-private (is-valid-optional-review (review (optional (string-ascii 300))))
  (match review
    some-review (and (> (len some-review) u0) (<= (len some-review) u300))
    true
  )
)

(define-private (is-valid-optional-notes (notes (optional (string-ascii 200))))
  (match notes
    some-notes (and (> (len some-notes) u0) (<= (len some-notes) u200))
    true
  )
)

;; UTILITY FUNCTIONS

(define-private (get-current-time)
  block-height ;; Using block height as time reference
)

(define-private (calculate-level (total-points uint))
  (if (>= total-points u10000)
    u5
    (if (>= total-points u5000)
      u4
      (if (>= total-points u2000)
        u3
        (if (>= total-points u500)
          u2
          u1
        )
      )
    )
  )
)

(define-private (generate-verification-hash (student principal) (course-id uint) (score uint))
  ;; Simple hash generation using available data
  (int-to-ascii (+ (+ course-id score) (get-current-time)))
)

(define-private (validate-score (score uint))
  (and (>= score u0) (<= score MAX_SCORE))
)

(define-private (check-prerequisites (student principal) (prerequisites (list 10 uint)))
  (fold check-single-prerequisite prerequisites true)
)

(define-private (check-single-prerequisite (course-id uint) (acc bool))
  (and acc
    (match (map-get? enrollments { student: tx-sender, course-id: course-id })
      enrollment (is-eq (get status enrollment) "completed")
      false
    )
  )
)

;; COURSE MANAGEMENT FUNCTIONS

(define-public (create-course 
  (name (string-ascii 100))
  (description (string-ascii 500))
  (credits uint)
  (difficulty-level (string-ascii 20))
  (prerequisites (list 10 uint))
  (max-enrollment uint)
)
  (let
    (
      (new-course-id (+ (var-get course-id-counter) u1))
      (current-time (get-current-time))
      (validated-name name)
      (validated-description description)
      (validated-difficulty difficulty-level)
      (validated-prerequisites prerequisites)
    )
    (asserts! (is-contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-valid-short-string validated-name) ERR_INVALID_INPUT)
    (asserts! (is-valid-string-input validated-description) ERR_INVALID_INPUT)
    (asserts! (is-valid-difficulty validated-difficulty) ERR_INVALID_INPUT)
    (asserts! (is-valid-prerequisites validated-prerequisites) ERR_INVALID_INPUT)
    (asserts! (> credits u0) ERR_INVALID_INPUT)
    (asserts! (> max-enrollment u0) ERR_INVALID_INPUT)

    ;; Create course
    (map-set courses
      { course-id: new-course-id }
      {
        name: validated-name,
        description: validated-description,
        instructor: tx-sender,
        credits: credits,
        difficulty-level: validated-difficulty,
        prerequisites: validated-prerequisites,
        max-enrollment: max-enrollment,
        current-enrollment: u0,
        is-active: true,
        created-at: current-time,
        updated-at: current-time
      }
    )

    ;; Update instructor profile
    (map-set instructor-profiles
      { instructor: tx-sender }
      (merge
        (default-to 
          {
            total-courses: u0,
            total-students: u0,
            average-rating: u0,
            join-date: current-time,
            is-verified: false,
            specializations: (list)
          }
          (map-get? instructor-profiles { instructor: tx-sender })
        )
        { 
          total-courses: (+ (default-to u0 (get total-courses (map-get? instructor-profiles { instructor: tx-sender }))) u1)
        }
      )
    )

    ;; Update counter
    (var-set course-id-counter new-course-id)
    (ok new-course-id)
  )
)

(define-public (update-course
  (course-id uint)
  (name (string-ascii 100))
  (description (string-ascii 500))
  (is-active bool)
)
  (let
    (
      (course-data (unwrap! (map-get? courses { course-id: course-id }) ERR_NOT_FOUND))
      (validated-name name)
      (validated-description description)
      (validated-course-id course-id)
    )
    (asserts! (is-valid-course-id validated-course-id) ERR_INVALID_INPUT)
    (asserts! (is-course-instructor validated-course-id) ERR_UNAUTHORIZED)
    (asserts! (is-valid-short-string validated-name) ERR_INVALID_INPUT)
    (asserts! (is-valid-string-input validated-description) ERR_INVALID_INPUT)

    (map-set courses
      { course-id: validated-course-id }
      (merge course-data {
        name: validated-name,
        description: validated-description,
        is-active: is-active,
        updated-at: (get-current-time)
      })
    )
    (ok true)
  )
)

;; ENROLLMENT FUNCTIONS

(define-public (enroll-in-course (course-id uint))
  (let
    (
      (validated-course-id course-id)
      (course-data (unwrap! (map-get? courses { course-id: validated-course-id }) ERR_NOT_FOUND))
      (current-time (get-current-time))
      (student-balance (stx-get-balance tx-sender))
    )
    (asserts! (is-valid-course-id validated-course-id) ERR_INVALID_INPUT)
    (asserts! (is-contract-active) ERR_UNAUTHORIZED)
    (asserts! (get is-active course-data) ERR_COURSE_NOT_ACTIVE)
    (asserts! (< (get current-enrollment course-data) (get max-enrollment course-data)) ERR_ENROLLMENT_CLOSED)
    (asserts! (>= student-balance (var-get enrollment-fee)) ERR_INSUFFICIENT_BALANCE)
    (asserts! (is-none (map-get? enrollments { student: tx-sender, course-id: validated-course-id })) ERR_ALREADY_EXISTS)
    (asserts! (check-prerequisites tx-sender (get prerequisites course-data)) ERR_PREREQUISITE_NOT_MET)

    ;; Transfer enrollment fee
    (try! (stx-transfer? (var-get enrollment-fee) tx-sender CONTRACT_OWNER))

    ;; Create enrollment record
    (map-set enrollments
      { student: tx-sender, course-id: validated-course-id }
      {
        enrolled-at: current-time,
        progress: u0,
        status: "enrolled",
        final-score: none,
        completion-date: none
      }
    )

    ;; Update course enrollment count
    (map-set courses
      { course-id: validated-course-id }
      (merge course-data {
        current-enrollment: (+ (get current-enrollment course-data) u1)
      })
    )

    ;; Update student profile
    (map-set student-profiles
      { student: tx-sender }
      (merge
        (default-to 
          {
            total-credits: u0,
            total-achievements: u0,
            total-points: u0,
            level: u1,
            join-date: current-time,
            last-activity: current-time,
            reputation-score: u100
          }
          (map-get? student-profiles { student: tx-sender })
        )
        { last-activity: current-time }
      )
    )

    (ok true)
  )
)

(define-public (update-progress (student principal) (course-id uint) (progress uint))
  (let
    (
      (validated-student student)
      (validated-course-id course-id)
      (validated-progress progress)
      (enrollment-data (unwrap! (map-get? enrollments { student: validated-student, course-id: validated-course-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-valid-principal validated-student) ERR_INVALID_INPUT)
    (asserts! (is-valid-course-id validated-course-id) ERR_INVALID_INPUT)
    (asserts! (is-valid-progress validated-progress) ERR_INVALID_INPUT)
    (asserts! (is-course-instructor validated-course-id) ERR_UNAUTHORIZED)

    (map-set enrollments
      { student: validated-student, course-id: validated-course-id }
      (merge enrollment-data {
        progress: validated-progress,
        status: (if (>= validated-progress u100) "completed" "in-progress")
      })
    )
    (ok true)
  )
)

;; ACHIEVEMENT FUNCTIONS

(define-public (create-achievement
  (name (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 50))
  (points uint)
  (requirements (string-ascii 300))
)
  (let
    (
      (new-achievement-id (+ (var-get achievement-id-counter) u1))
      (current-time (get-current-time))
      (validated-name name)
      (validated-description description)
      (validated-category category)
      (validated-requirements requirements)
    )
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (is-valid-short-string validated-name) ERR_INVALID_INPUT)
    (asserts! (is-valid-string-input validated-description) ERR_INVALID_INPUT)
    (asserts! (is-valid-category validated-category) ERR_INVALID_INPUT)
    (asserts! (is-valid-requirements validated-requirements) ERR_INVALID_INPUT)
    (asserts! (> points u0) ERR_INVALID_INPUT)

    (map-set achievements
      { achievement-id: new-achievement-id }
      {
        name: validated-name,
        description: validated-description,
        category: validated-category,
        points: points,
        requirements: validated-requirements,
        is-active: true,
        created-by: tx-sender,
        created-at: current-time
      }
    )

    (var-set achievement-id-counter new-achievement-id)
    (ok new-achievement-id)
  )
)

(define-public (award-achievement (student principal) (achievement-id uint) (score uint) (notes (optional (string-ascii 200))))
  (let
    (
      (validated-student student)
      (validated-achievement-id achievement-id)
      (validated-score score)
      (validated-notes notes)
      (achievement-data (unwrap! (map-get? achievements { achievement-id: validated-achievement-id }) ERR_NOT_FOUND))
      (current-time (get-current-time))
      (student-profile (default-to 
        {
          total-credits: u0,
          total-achievements: u0,
          total-points: u0,
          level: u1,
          join-date: current-time,
          last-activity: current-time,
          reputation-score: u100
        }
        (map-get? student-profiles { student: validated-student })
      ))
    )
    (asserts! (is-valid-principal validated-student) ERR_INVALID_INPUT)
    (asserts! (is-valid-achievement-id validated-achievement-id) ERR_INVALID_INPUT)
    (asserts! (is-valid-optional-notes validated-notes) ERR_INVALID_INPUT)
    (asserts! (or (is-contract-owner) (is-eq tx-sender (get created-by achievement-data))) ERR_UNAUTHORIZED)
    (asserts! (get is-active achievement-data) ERR_ACHIEVEMENT_LOCKED)
    (asserts! (validate-score validated-score) ERR_INVALID_SCORE)
    (asserts! (is-none (map-get? student-achievements { student: validated-student, achievement-id: validated-achievement-id })) ERR_ALREADY_EXISTS)

    ;; Award achievement
    (map-set student-achievements
      { student: validated-student, achievement-id: validated-achievement-id }
      {
        earned-at: current-time,
        verified-by: tx-sender,
        score: validated-score,
        notes: validated-notes
      }
    )

    ;; Update student profile
    (let
      (
        (new-total-points (+ (get total-points student-profile) (get points achievement-data)))
        (new-total-achievements (+ (get total-achievements student-profile) u1))
      )
      (map-set student-profiles
        { student: validated-student }
        (merge student-profile {
          total-achievements: new-total-achievements,
          total-points: new-total-points,
          level: (calculate-level new-total-points),
          last-activity: current-time
        })
      )
    )

    (ok true)
  )
)

;; CERTIFICATE FUNCTIONS

(define-public (issue-certificate 
  (student principal) 
  (course-id uint) 
  (final-score uint)
  (grade (string-ascii 10))
)
  (let
    (
      (validated-student student)
      (validated-course-id course-id)
      (validated-score final-score)
      (validated-grade grade)
      (enrollment-data (unwrap! (map-get? enrollments { student: validated-student, course-id: validated-course-id }) ERR_NOT_FOUND))
      (course-data (unwrap! (map-get? courses { course-id: validated-course-id }) ERR_NOT_FOUND))
      (new-certificate-id (+ (var-get certificate-id-counter) u1))
      (current-time (get-current-time))
      (verification-hash (generate-verification-hash validated-student validated-course-id validated-score))
    )
    (asserts! (is-valid-principal validated-student) ERR_INVALID_INPUT)
    (asserts! (is-valid-course-id validated-course-id) ERR_INVALID_INPUT)
    (asserts! (is-course-instructor validated-course-id) ERR_UNAUTHORIZED)
    (asserts! (validate-score validated-score) ERR_INVALID_SCORE)
    (asserts! (>= validated-score MIN_PASSING_SCORE) ERR_INVALID_SCORE)
    (asserts! (is-valid-grade validated-grade) ERR_INVALID_INPUT)

    ;; Issue certificate
    (map-set certificates
      { certificate-id: new-certificate-id }
      {
        student: validated-student,
        course-id: validated-course-id,
        achievement-id: none,
        issued-by: tx-sender,
        issued-at: current-time,
        grade: validated-grade,
        final-score: validated-score,
        verification-hash: verification-hash,
        is-revoked: false
      }
    )

    ;; Update enrollment status
    (map-set enrollments
      { student: validated-student, course-id: validated-course-id }
      (merge enrollment-data {
        status: "completed",
        final-score: (some validated-score),
        completion-date: (some current-time)
      })
    )

    ;; Update student profile with credits
    (let
      (
        (student-profile (default-to 
          {
            total-credits: u0,
            total-achievements: u0,
            total-points: u0,
            level: u1,
            join-date: current-time,
            last-activity: current-time,
            reputation-score: u100
          }
          (map-get? student-profiles { student: validated-student })
        ))
      )
      (map-set student-profiles
        { student: validated-student }
        (merge student-profile {
          total-credits: (+ (get total-credits student-profile) (get credits course-data)),
          last-activity: current-time
        })
      )
    )

    (var-set certificate-id-counter new-certificate-id)
    (ok new-certificate-id)
  )
)

(define-public (revoke-certificate (certificate-id uint))
  (let
    (
      (validated-certificate-id certificate-id)
      (certificate-data (unwrap! (map-get? certificates { certificate-id: validated-certificate-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-valid-certificate-id validated-certificate-id) ERR_INVALID_INPUT)
    (asserts! (or (is-contract-owner) (is-eq tx-sender (get issued-by certificate-data))) ERR_UNAUTHORIZED)
    (asserts! (not (get is-revoked certificate-data)) ERR_NOT_FOUND)

    (map-set certificates
      { certificate-id: validated-certificate-id }
      (merge certificate-data { is-revoked: true })
    )
    (ok true)
  )
)

;; REVIEW AND RATING FUNCTIONS

(define-public (submit-course-review (course-id uint) (rating uint) (review (optional (string-ascii 300))))
  (let
    (
      (validated-course-id course-id)
      (validated-rating rating)
      (validated-review review)
      (enrollment-data (unwrap! (map-get? enrollments { student: tx-sender, course-id: validated-course-id }) ERR_NOT_FOUND))
      (current-time (get-current-time))
    )
    (asserts! (is-valid-course-id validated-course-id) ERR_INVALID_INPUT)
    (asserts! (is-contract-active) ERR_UNAUTHORIZED)
    (asserts! (is-valid-rating validated-rating) ERR_INVALID_INPUT)
    (asserts! (is-valid-optional-review validated-review) ERR_INVALID_INPUT)
    (asserts! (is-eq (get status enrollment-data) "completed") ERR_UNAUTHORIZED)

    (map-set course-reviews
      { student: tx-sender, course-id: validated-course-id }
      {
        rating: validated-rating,
        review: validated-review,
        submitted-at: current-time
      }
    )
    (ok true)
  )
)

;; ADMIN FUNCTIONS

(define-public (pause-contract)
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

(define-public (set-enrollment-fee (new-fee uint))
  (let
    (
      (validated-fee new-fee)
    )
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (is-valid-fee validated-fee) ERR_INVALID_INPUT)
    (var-set enrollment-fee validated-fee)
    (ok true)
  )
)

(define-public (verify-instructor (instructor principal))
  (let
    (
      (validated-instructor instructor)
      (instructor-profile (unwrap! (map-get? instructor-profiles { instructor: validated-instructor }) ERR_NOT_FOUND))
    )
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (is-valid-principal validated-instructor) ERR_INVALID_INPUT)
    
    (map-set instructor-profiles
      { instructor: validated-instructor }
      (merge instructor-profile { is-verified: true })
    )
    (ok true)
  )
)

;; READ-ONLY FUNCTIONS

(define-read-only (get-course (course-id uint))
  (map-get? courses { course-id: course-id })
)

(define-read-only (get-enrollment (student principal) (course-id uint))
  (map-get? enrollments { student: student, course-id: course-id })
)

(define-read-only (get-achievement (achievement-id uint))
  (map-get? achievements { achievement-id: achievement-id })
)

(define-read-only (get-student-achievement (student principal) (achievement-id uint))
  (map-get? student-achievements { student: student, achievement-id: achievement-id })
)

(define-read-only (get-certificate (certificate-id uint))
  (map-get? certificates { certificate-id: certificate-id })
)

(define-read-only (get-student-profile (student principal))
  (map-get? student-profiles { student: student })
)

(define-read-only (get-instructor-profile (instructor principal))
  (map-get? instructor-profiles { instructor: instructor })
)

(define-read-only (get-course-review (student principal) (course-id uint))
  (map-get? course-reviews { student: student, course-id: course-id })
)

(define-read-only (get-contract-info)
  {
    owner: CONTRACT_OWNER,
    paused: (var-get contract-paused),
    enrollment-fee: (var-get enrollment-fee),
    total-courses: (var-get course-id-counter),
    total-achievements: (var-get achievement-id-counter),
    total-certificates: (var-get certificate-id-counter)
  }
)

(define-read-only (verify-certificate (certificate-id uint))
  (match (map-get? certificates { certificate-id: certificate-id })
    certificate-data 
      (ok {
        valid: (not (get is-revoked certificate-data)),
        student: (get student certificate-data),
        course-id: (get course-id certificate-data),
        final-score: (get final-score certificate-data),
        issued-at: (get issued-at certificate-data),
        verification-hash: (get verification-hash certificate-data)
      })
    ERR_NOT_FOUND
  )
)