;; Technician Verification Contract
;; Validates qualified service providers

(define-constant contract-owner tx-sender)

;; Technician data structure
(define-map technicians
  { technician-id: principal }
  {
    name: (string-ascii 100),
    certifications: (list 10 (string-ascii 100)),
    specializations: (list 10 (string-ascii 100)),
    active: bool,
    rating: uint,
    total-services: uint
  }
)

;; Certification to asset type mapping
(define-map certification-requirements
  { asset-type: (string-ascii 100) }
  { required-certifications: (list 10 (string-ascii 100)) }
)

;; Register a new technician
(define-public (register-technician
    (name (string-ascii 100))
    (certifications (list 10 (string-ascii 100)))
    (specializations (list 10 (string-ascii 100))))
  (let
    (
      (technician-id tx-sender)
    )
    ;; Add technician to map
    (map-set technicians
      { technician-id: technician-id }
      {
        name: name,
        certifications: certifications,
        specializations: specializations,
        active: true,
        rating: u0,
        total-services: u0
      }
    )

    (ok true)
  )
)

;; Get technician details
(define-read-only (get-technician (technician-id principal))
  (map-get? technicians { technician-id: technician-id })
)

;; Check if technician is qualified for asset type
(define-read-only (is-qualified (technician-id principal) (asset-type (string-ascii 100)))
  (let
    (
      (technician (map-get? technicians { technician-id: technician-id }))
      (requirements (map-get? certification-requirements { asset-type: asset-type }))
    )
    (if (and (is-some technician) (is-some requirements))
      true ;; Simplified - assume qualified if both exist
      false
    )
  )
)

;; Set certification requirements for asset type (admin only)
(define-public (set-certification-requirements
    (asset-type (string-ascii 100))
    (required-certifications (list 10 (string-ascii 100))))
  (begin
    ;; Only contract owner can set requirements
    (asserts! (is-eq tx-sender contract-owner) (err u1))

    (map-set certification-requirements
      { asset-type: asset-type }
      { required-certifications: required-certifications }
    )

    (ok true)
  )
)

;; Update technician rating after service
(define-public (update-technician-rating (technician-id principal) (rating uint))
  (let
    (
      (technician (unwrap! (map-get? technicians { technician-id: technician-id }) (err u1)))
      (current-rating (get rating technician))
      (total-services (get total-services technician))
      (new-total-services (+ total-services u1))
      (new-rating (/ (+ (* current-rating total-services) rating) new-total-services))
    )
    ;; Rating must be between 1 and 5
    (asserts! (and (>= rating u1) (<= rating u5)) (err u2))

    ;; Update technician rating
    (map-set technicians
      { technician-id: technician-id }
      (merge technician
        {
          rating: new-rating,
          total-services: new-total-services
        }
      )
    )

    (ok true)
  )
)

;; Deactivate a technician
(define-public (deactivate-technician (technician-id principal))
  (let
    (
      (technician (unwrap! (map-get? technicians { technician-id: technician-id }) (err u1)))
    )
    ;; Only the technician or contract owner can deactivate
    (asserts! (or (is-eq tx-sender technician-id) (is-eq tx-sender contract-owner)) (err u2))

    ;; Update technician status
    (map-set technicians
      { technician-id: technician-id }
      (merge technician { active: false })
    )

    (ok true)
  )
)
