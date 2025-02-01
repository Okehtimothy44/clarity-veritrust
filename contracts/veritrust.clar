;; VeriTrust - Product Authentication Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))

;; Data vars
(define-map manufacturers principal bool)
(define-map products 
    { product-id: (string-ascii 64) }
    {
        manufacturer: principal,
        timestamp: uint,
        metadata: (string-ascii 256),
        current-owner: principal,
        is-verified: bool
    }
)

;; New ownership history tracking
(define-map ownership-history
    { product-id: (string-ascii 64) }
    { history: (list 50 { owner: principal, timestamp: uint }) }
)

;; Private functions
(define-private (is-manufacturer (address principal))
    (default-to false (map-get? manufacturers address))
)

(define-private (add-to-history (product-id (string-ascii 64)) (new-owner principal))
    (let (
        (current-history (unwrap! (map-get? ownership-history { product-id: product-id }) 
            (tuple (history (list)))))
        (new-entry (tuple (owner new-owner) (timestamp block-height)))
    )
    (map-set ownership-history
        { product-id: product-id }
        { history: (unwrap! (as-max-len? (append (get history current-history) new-entry) u50) 
            (get history current-history)) }
    ))
)

;; Public functions
(define-public (add-manufacturer (manufacturer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (ok (map-set manufacturers manufacturer true))
    )
)

(define-public (register-product (product-id (string-ascii 64)) (metadata (string-ascii 256)))
    (let (
        (exists (map-get? products { product-id: product-id }))
    )
    (asserts! (is-manufacturer tx-sender) err-unauthorized)
    (asserts! (is-none exists) err-already-registered)
    (map-set ownership-history 
        { product-id: product-id }
        { history: (list (tuple (owner tx-sender) (timestamp block-height))) }
    )
    (ok (map-set products
        { product-id: product-id }
        {
            manufacturer: tx-sender,
            timestamp: block-height,
            metadata: metadata,
            current-owner: tx-sender,
            is-verified: true
        }
    )))
)

(define-public (transfer-ownership (product-id (string-ascii 64)) (new-owner principal))
    (let (
        (product (unwrap! (map-get? products { product-id: product-id }) err-not-found))
    )
    (asserts! (is-eq (get current-owner product) tx-sender) err-unauthorized)
    (add-to-history product-id new-owner)
    (ok (map-set products
        { product-id: product-id }
        (merge product { current-owner: new-owner })
    )))
)

;; Read only functions
(define-read-only (verify-product (product-id (string-ascii 64)))
    (ok (map-get? products { product-id: product-id }))
)

(define-read-only (get-manufacturer-status (address principal))
    (ok (is-manufacturer address))
)

(define-read-only (get-product-owner (product-id (string-ascii 64)))
    (ok (get current-owner (default-to 
        {
            manufacturer: contract-owner,
            timestamp: u0,
            metadata: "",
            current-owner: contract-owner,
            is-verified: false
        }
        (map-get? products { product-id: product-id })
    )))
)

(define-read-only (get-ownership-history (product-id (string-ascii 64)))
    (ok (default-to 
        { history: (list) }
        (map-get? ownership-history { product-id: product-id })
    ))
)
