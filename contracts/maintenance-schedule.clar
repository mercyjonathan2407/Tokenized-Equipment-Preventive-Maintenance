;; Maintenance Schedule Contract
;; Defines required service intervals for equipment

(define-map maintenance-schedules
  { asset-id: uint }
  {
    interval-days: uint,
    last-maintenance: uint,
    next-maintenance: uint,
    maintenance-tasks: (list 20 (string-ascii 100))
  }
)

;; Create or update maintenance schedule
(define-public (set-maintenance-schedule
    (asset-id uint)
    (interval-days uint)
    (maintenance-tasks (list 20 (string-ascii 100))))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time u0)))
    )
    ;; Set maintenance schedule
    (map-set maintenance-schedules
      { asset-id: asset-id }
      {
        interval-days: interval-days,
        last-maintenance: u0, ;; No maintenance performed yet
        next-maintenance: (+ current-time (* interval-days u86400)), ;; Convert days to seconds
        maintenance-tasks: maintenance-tasks
      }
    )

    (ok true)
  )
)

;; Get maintenance schedule for an asset
(define-read-only (get-maintenance-schedule (asset-id uint))
  (map-get? maintenance-schedules { asset-id: asset-id })
)

;; Check if maintenance is due
(define-read-only (is-maintenance-due (asset-id uint))
  (let
    (
      (schedule (map-get? maintenance-schedules { asset-id: asset-id }))
      (current-time (unwrap-panic (get-block-info? time u0)))
    )
    (if (is-some schedule)
      (>= current-time (get next-maintenance (unwrap-panic schedule)))
      false
    )
  )
)

;; Get days until next maintenance
(define-read-only (days-until-maintenance (asset-id uint))
  (let
    (
      (schedule (map-get? maintenance-schedules { asset-id: asset-id }))
      (current-time (unwrap-panic (get-block-info? time u0)))
    )
    (if (is-some schedule)
      (let
        (
          (next (get next-maintenance (unwrap-panic schedule)))
          (seconds-remaining (if (> next current-time) (- next current-time) u0))
        )
        (/ seconds-remaining u86400) ;; Convert seconds to days
      )
      u0
    )
  )
)

;; Get maintenance tasks for an asset
(define-read-only (get-maintenance-tasks (asset-id uint))
  (let
    (
      (schedule (map-get? maintenance-schedules { asset-id: asset-id }))
    )
    (if (is-some schedule)
      (ok (get maintenance-tasks (unwrap-panic schedule)))
      (err u1)
    )
  )
)

;; Update last maintenance and calculate next maintenance
(define-public (update-last-maintenance (asset-id uint) (maintenance-time uint) (next-maintenance-time uint))
  (let
    (
      (schedule (unwrap! (map-get? maintenance-schedules { asset-id: asset-id }) (err u1)))
    )
    ;; Update maintenance schedule
    (map-set maintenance-schedules
      { asset-id: asset-id }
      (merge schedule
        {
          last-maintenance: maintenance-time,
          next-maintenance: next-maintenance-time
        }
      )
    )

    (ok true)
  )
)
