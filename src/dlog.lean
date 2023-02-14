import measure_theory.probability_mass_function 
import uniform

noncomputable theory 

section DL

variables (G : Type) [fintype G] [group G]
          (g : G) (g_gen_G : ∀ (x : G), x ∈ subgroup.gpowers g)
          (q : ℕ) [fact (0 < q)] (G_card_q : fintype.card G = q) 
          (A : G → pmf (zmod q))

include g_gen_G G_card_q

def DLG : pmf (zmod q) := 
do 
  α ← uniform_zmod q,
  α' ←  A (g^α.val),
  pure α'

def DLadv : Prop := ((DLG G g g_gen_G q G_card_q A).1 1 : ℝ) = ((DLG G g g_gen_G q G_card_q A).2 1 : ℝ)


#check DLG G g g_gen_G q G_card_q A 

end DL