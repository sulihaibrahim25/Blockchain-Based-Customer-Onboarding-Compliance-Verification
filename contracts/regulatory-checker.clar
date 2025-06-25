;; Regulatory Checking Contract
;; Checks regulatory compliance

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u200))
(define-constant ERR-RULE-NOT-FOUND (err u201))
(define-constant ERR-RULE-ALREADY-EXISTS (err u202))
(define-constant ERR-COMPLIANCE-FAILED (err u203))

;; Data Variables
(define-data-var next-rule-id uint u1)

;; Data Maps
(define-map regulatory-rules
  { rule-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    jurisdiction: (string-ascii 30),
    requirement-type: (string-ascii 20),
    active: bool,
    created-at: uint
  }
)

(define-map compliance-checks
  { customer-id: (string-ascii 50), rule-id: uint }
  {
    status: (string-ascii 20),
    checked-by: principal,
    checked-at: uint,
    notes: (string-ascii 200)
  }
)

;; Public Functions

;; Add a new regulatory rule
(define-public (add-regulatory-rule
  (name (string-ascii 50))
  (description (string-ascii 200))
  (jurisdiction (string-ascii 30))
  (requirement-type (string-ascii 20)))
  (let ((rule-id (var-get next-rule-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)

    (map-set regulatory-rules
      { rule-id: rule-id }
      {
        name: name,
        description: description,
        jurisdiction: jurisdiction,
        requirement-type: requirement-type,
        active: true,
        created-at: block-height
      }
    )

    (var-set next-rule-id (+ rule-id u1))
    (ok rule-id)
  )
)

;; Perform compliance check
(define-public (check-compliance
  (customer-id (string-ascii 50))
  (rule-id uint)
  (status (string-ascii 20))
  (notes (string-ascii 200)))
  (let ((rule (unwrap! (map-get? regulatory-rules { rule-id: rule-id }) ERR-RULE-NOT-FOUND)))
    ;; In a real implementation, this would verify the caller is an approved verifier

    (map-set compliance-checks
      { customer-id: customer-id, rule-id: rule-id }
      {
        status: status,
        checked-by: tx-sender,
        checked-at: block-height,
        notes: notes
      }
    )
    (ok true)
  )
)

;; Deactivate a regulatory rule
(define-public (deactivate-rule (rule-id uint))
  (let ((rule (unwrap! (map-get? regulatory-rules { rule-id: rule-id }) ERR-RULE-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)

    (map-set regulatory-rules
      { rule-id: rule-id }
      (merge rule { active: false })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get regulatory rule details
(define-read-only (get-regulatory-rule (rule-id uint))
  (map-get? regulatory-rules { rule-id: rule-id })
)

;; Get compliance check result
(define-read-only (get-compliance-check (customer-id (string-ascii 50)) (rule-id uint))
  (map-get? compliance-checks { customer-id: customer-id, rule-id: rule-id })
)

;; Check if customer is compliant with all active rules
(define-read-only (is-customer-compliant (customer-id (string-ascii 50)))
  ;; Simplified implementation - in practice would check all active rules
  true
)

;; Get total number of rules
(define-read-only (get-rule-count)
  (- (var-get next-rule-id) u1)
)
