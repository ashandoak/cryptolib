/-
 -----------------------------------------------------------
  Generic commitments
 -----------------------------------------------------------
-/

import data.zmod.basic
import measure_theory.probability_mass_function
import to_mathlib
import uniform

noncomputable theory 

/-
  G = The agreed upon group (order q and generator g)
  M = message space
  D = space of opening values (order q)
  C = commitment space (in theory includes committed message and opening value computed by committer)
-/

/-
Commitment phase:
1. Run Gen to establish public security parameters.
2. C samples an opening value, computes commitment, and sends commitment to R.

Verification phase:
3. C sends message, opening value pair to R.
4. R accepts or rejects commitment depending on result of verification.
-/

/-
From Boneh & Shoup:
A security parameter (λ) and system parameter (Λ) are used to index families of key spaces, message spaces and ciphertext spaces. 
-/

variables {G M D C A_state : Type} [decidable_eq M]
          (gen : pmf G) -- generates the public parameter, h ∈ G
          (commit : G → M → pmf (C × D) )
          (verify : G → C → D → M → zmod 2)
          (BindingAdversary : G → pmf (C × D × D × M × M)) -- how to ensure these are two different Ms?
          (HidingAdversary1 : G → pmf (M × M × A_state)) -- double check how Lupo handles state
          (HidingAdversary2 : G → C → A_state → pmf (zmod 2) )

/-
Simulates running the program and returns 1 with prob 1 if verify holds
`d : D` is passed in rather than generate by the commiter

-- but we don't need d here now, since we're generating h...
-/

def commit_verify (m : M) : pmf (zmod 2) := -- formerly included a (d : D) parameter
do 
  h ← gen, 
  c ← commit h m, 
  pure (if verify h c.1 c.2 m = 1 then 1 else 0) --c.2 is the opening value

/- 
  A commitment protocol is correct if verification undoes 
  commitment with probability 1

  This was formerly:
    Prop := ∀ (m : M) (d : D), commit_verify gen commit verify m d = pure 1 

  But this should this be ∀m, not ∀m,d? - removed the (d : D) parameter (below) as the opening value is generated by commit and the result is passed to verify
-/
def commitment_correctness : Prop := ∀ (m : M), commit_verify gen commit verify m = pure 1 

#check commitment_correctness


/-
  Binding: "no adversary (either powerful or computationally bounded) can generate c, m = m' and d, d' such that both Verify(c, m, d) and Verify(c, m', d') accept"
-/
def BG : pmf (zmod 2) :=
do 
  h ← gen, 
  bc ← BindingAdversary h, --pmf (C × D × D × M × M)
  -- Def. of binding in B&S pg. 337
  -- As per comment above - how to ensure the Ms are unique?
  -- Verify that both return 1
  -- Commitments are valid commitments to a message
  let b := verify h bc.1 bc.2.1 bc.2.2.2.1,
  let b' := verify h bc.1 bc.2.2.1 bc.2.2.2.2,
  -- let b'' := (if bc.2.2.2.1 = bc.2.2.2.2 
  pure (if bc.2.2.2.1 = bc.2.2.2.2 then 0 else b * b')
  
local notation `Pr[BG(A)]` := (BG gen verify BindingAdversary 1 : ℝ)

def computational_binding_property (ε : nnreal) : Prop := abs (Pr[BG(A)] - 1/2) ≤ ε -- the 1/2 term is necessary here?

#check computational_binding_property


-- TODO: General defintion of perfect hiding

-- Computational hiding

/- 
  Hiding: "commitment c does not leak information about m (either perfect secrecy, or computational indistinguishability)"
-/
-- Split into two phases: 1. return two M; 2. return bit

def docommit (h : G) (m : M) : pmf C :=
do
  c ← commit h m, 
  pure c.1 -- return just the commit, not the opening value


-- Perfect hiding strategy: Use uniformity prop. of group to replace the commit with something completely random
-- Adv with no knowledge of the message can't guess the message with greater prob than 1/|M|
-- Any adv that wins the perf. hiding game also wins the message guessing game - contradiction
-- Breaking the perfect hiding game breaks the impossible message game
-- Perf. hiding as equality between pmfs ∀m1,m2 
-- Pedersen commitments are uniform so equivalence shows 

def perfect_hiding_property : Prop := ∀ (h : G) (m1 m2 : M), docommit commit h m1 = docommit commit h m2 -- This is an equality between distributions - how is this proved?

#check docommit
def HG : pmf (zmod 2) := 
do 
  hc ← HidingAdversary1,
  b ← uniform_2,
  c ← commit hc.b,
  let b' := A c,
  pure (if b = b' 1 else 0)

local `Pr[HG(A)]` := (HG verify HidingAdversary 1 : ℝ) 

#check HG commit HidingAdversary A 

def computational_hiding_property (ε : nnreal) : Prop := abs (Pr[HG(A)] - 1/2) ≤ ε

-- game where adv. generates two messages
-- commiter commits to one chosen at random
-- opening value has to be an input to commit, but we don't really care what it is (could be a series of coin flips in the process or, could be a random string provided as input) 


-- Also need perfect hiding
-- Definition of perfect binding...? Has anyone written this down?