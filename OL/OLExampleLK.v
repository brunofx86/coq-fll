(** * System LK for propositional classical logic encoded as an LL theory

This file encodes the inference rules of the system LK (propositional
classical logic). Using [OLCutElimination] we prove the cut-elimination
theorem for this system .
 *)

Require Export FLL.OL.OLCutElimTheorem.
Require Import Coq.Init.Nat.
Require Import FLL.Misc.Permutations.

Export ListNotations.
Export LLNotations.
Set Implicit Arguments.


(** ** Syntax *)
(* units: true and false *)
Inductive Constants := TT | FF  .
(* conjunction, disjunction and implication *)
Inductive Connectives := AND | OR | IMPL  .
(* no quantifiers *)
Inductive Quantifiers := .
(* Although negation is not needed we keep it for illustrative purposes *) 
Inductive UConnectives := NEG .  

Instance SimpleOLSig : OLSyntax:=
  {|
    OLType := nat;
    constants := Constants ;
    uconnectives := UConnectives;
    connectives := Connectives ;
    quantifiers := Quantifiers
  |}.


(** ** Inference rules *)

(** *** Constants *)
Definition rulesCTE (c:constants) :=
  match c with
  | TT => {| rc_rightBody := top;
             rc_leftBody := zero |}
  | FF => {| rc_rightBody := zero; (* No right introduction rule *)
             rc_leftBody := top  |}
  end.

(** *** Unary connectives *)
Definition rulesUC  (c:uconnectives) :=
  match c with
  | neg => {| ru_rightBody := fun F => (atom (down F)) ;
              ru_leftBody := fun F => (atom (up F))
           |}
  end.

(** *** Binary connectives *)
Definition rulesBC (c :connectives) :=
  match c with
  | AND => {| rb_rightBody := fun F G => (atom (up F)) ** (atom (up G) );
              rb_leftBody  := fun F G => (atom (down F) ) $ (atom (down G)) |}
  | OR => {| rb_rightBody := fun F G => (atom (up F)) op (atom (up G) );
             rb_leftBody  := fun F G => (atom (down F) ) & (atom (down G)) |}
  | IMPL => {| rb_rightBody := fun F G => (atom (down F)) $  (atom (up G) );
               rb_leftBody  := fun F G => (atom (up F) ) ** (atom (down G)) |}
  end.

(** *** Quantifiers *)
Definition rulesQC (c :quantifiers) :=
  match c return ruleQ with
  end.


Instance SimpleOORUles : OORules :=
  {|
    rulesCte := rulesCTE ;
    rulesUnary := rulesUC ;
    rulesBin := rulesBC;
    rulesQ := rulesQC
  |}.

(** ** Well-formedness conditions *)

Definition down' : uexp -> atm := down.
Definition up' : uexp -> atm := up.
Hint Unfold down' up' : core .



(** *** Constants *)
Lemma wellFormedConstant_p : wellFormedCte.
Proof with WFSolver.
  unfold wellFormedCte;intros.
  destruct lab;destruct s.
  (** TT on the left *)
  exists BCFail.
  WFFailSolver.
  (* TT on the right *)
  exists BCAxiom...
  apply TT_Top.
  (* FF on the left *)
  exists BCAxiom...
  apply FF_Top.
  + (* FF on the right *)
    exists BCFail.
    WFFailSolver.
Qed.


(** *** Unary connectives *)

Lemma wellFormedUnary_p : wellFormedUnary.
Proof with WFSolver.
  unfold wellFormedUnary;intros.
  destruct lab.
  destruct s; exists BOneP ; intro F ;intros n Hseq HIs...
  + (* left rule *)
    exists  [atom (up' F)]. 
    exists (@nil oo).
    InvTriAll.
    eexists. exists 3...
    
    left. exists N...
    decide3' (makeLRuleUnary NEG F).
    tensor'  [ (atom (down (t_ucon NEG F)))] Delta1...

    eexists. exists 3...
    rewrite H1.
    right...
    decide3' (makeLRuleUnary NEG F).
    tensor'  (@nil oo) Delta1;solveLL'... 
  + (* right rule *)
    exists  [atom (down' F)]. 
    exists (@nil oo).
    InvTriAll.
    eexists. exists 3...
    
    left. exists N...
    decide3' (makeRRuleUnary NEG F).
    tensor'  [ (atom (up (t_ucon NEG F)))] Delta1;solveLL'... 

    eexists. exists 3...
    rewrite H1.
    right...
    decide3' (makeRRuleUnary NEG F).
    tensor'  (@nil oo) Delta1 ...
Qed.


(** *** Binary connectives *)
Lemma wellFormedBinary_p : wellFormedBinary.
Proof with WFSolver.
  unfold wellFormedBinary;intros.
  destruct lab;destruct s.
  (* Conjunction left *)
  exists BOneP...
  apply ANDL_Par.

  (* Conjunction right *)
  exists BTwoPM...
  eapply ANDR_Tensor.
    
  (* Disjunction left *)
  exists BTwoPA...
  apply ORL_With.

  (* Disjunction right *)
  exists BOneP...
  apply ORR_Plus.
  (* implication left *)
  exists BTwoPM...
  apply IMPL_Tensor.
  (* implication right *)
  exists BOneP...
  apply IMPR_Par.
Qed.



(** *** Quantifiers *)
Lemma wellFormedQuantifier_p : wellFormedQuantifier.
Proof with solveF.
  unfold wellFormedQuantifier. intros.
  destruct lab.
Qed.

Lemma wellFormedTheory_p : wellFormedTheory.
  split.
  apply wellFormedConstant_p.
  split.
  apply wellFormedUnary_p.
  split; [apply wellFormedBinary_p | apply wellFormedQuantifier_p].
Qed.

(** ** Cut-coherency properties *)


(** *** Constants *)
Lemma CheckCutCoherenceTT: CutCoherenceCte (rulesCTE TT).
Proof with solveF.
  unfold CutCoherenceCte;intros.
  simpl.
  solveLL'.
Qed.

Lemma CheckCutCoherenceFF: CutCoherenceCte (rulesCTE FF).
Proof with solveF.
  unfold CutCoherenceCte;intros.
  simpl.
  solveLL'.
Qed.

(** *** Unary connectives *)
Lemma CheckCutCoherenceNeg: CutCoherenceUnary (rulesUC NEG).
Proof with solveF.
  unfold CutCoherenceUnary;intros.
  simpl.
  solveLL'.
  (* Using the CUT rule *)
  decide3' ((atom (up F) ) ** (atom (down F) )).  econstructor;eauto.
  tensor' [perp (up F) ] [ perp (down F)   ];solveLL'.
Qed.


(** *** Binary Connectives *)
Lemma CutCoherenceAND: CutCoherenceBin (rulesBC AND).
Proof with solveF.
  unfold CutCoherenceBin;intros.
  simpl.
  solveLL'.
  decide3' ((atom (up F) ) ** (atom (down F) )). econstructor;eauto using le_max_l.
  tensor' [perp (up F) ] [ perp (up G) ; (perp (down F) ) ** perp (down G) ];solveLL'.
  decide3' ((atom (up G) ) ** atom (down G) ). econstructor;eauto using le_max_r.
  solveLL'.
  tensor' [perp (up G)  ][ (perp (down F) ) ** perp (down G) ; atom (down F) ];solveLL'.
  decide1' ((perp (down F) ) ** perp (down G) ).
  tensor'... 
Qed.

Lemma CutCoherenceOR: CutCoherenceBin (rulesBC OR).
Proof with solveF.
  unfold CutCoherenceBin;intros.
  simpl.
  solveLL'.
  decide3' ((atom (up F) ) ** (atom (down F) )). econstructor;eauto using le_max_l.
  tensor' [perp (up F) ] [  perp (down F) op perp (down G)];solveLL'.
  decide1' (perp (down F) op perp (down G)) .

  decide3' ((atom (up G) ) ** (atom (down G) )). econstructor;eauto using le_max_r.
  tensor' [perp (up G) ] [  perp (down F) op perp (down G)];solveLL'.
  decide1' (perp (down F) op perp (down G)) .
Qed.

Lemma CutCoherenceIMPL: CutCoherenceBin (rulesBC IMPL).
Proof with solveF.
  unfold CutCoherenceBin;intros.
  simpl.
  solveLL'.
  decide3' ((atom (up F) ) ** (atom (down F) )). econstructor;eauto using le_max_l.
  tensor' [perp (up F)]  [perp (down F) ** perp (up G); perp (down G)];solveLL'. 
  decide3' ((atom (up G) ) ** (atom (down G) )). econstructor;eauto using le_max_r.
  tensor' [perp (down F) ** perp (up G); atom (down F)] [perp (down G)];solveLL'.
  decide1' (perp (down F) ** perp (up G)) .
  tensor' [atom (down F) ][ atom (up G)] . 
Qed.


Lemma CutCoherence_p : CutCoherence .
  split;intros; try destruct lab;
    auto using CheckCutCoherenceTT, CheckCutCoherenceFF .
  split;intros; try destruct lab;
    auto using CheckCutCoherenceNeg .
  split;intros; try destruct lab;
    auto using CutCoherenceAND, CutCoherenceOR, CutCoherenceIMPL .
Qed.

(** The theory is well formed: cut-coherence holds and all the rules
are bipoles *)
Lemma wellTheory_p : wellTheory.
  split;auto using CutCoherence_p,  wellFormedTheory_p.
Qed.

Hint Unfold  OLTheoryIsFormula ConstantsFormulas UConnectivesFormulas ConnectivesFormulas QuantifiersFormulas : core .
Hint Unfold  OLTheoryIsFormulaD ConstantsFormulasD UConnectivesFormulasD ConnectivesFormulasD QuantifiersFormulasD :core.

Theorem  OLTheoryIsFormula_p :  OLTheoryIsFormula.
Proof with SolveIsFormulas.
  split;autounfold...
  intro;destruct lab...
  intro;destruct lab...
Qed.

Theorem  OLTheoryIsFormulaD_p :  OLTheoryIsFormulaD.
Proof with SolveIsFormulas.
  split;autounfold...
  intro;destruct lab...
  intro;destruct lab...
Qed.
  
(** The cut-elimination theorem instantiated for LK *)
Check OLCutElimination wellTheory_p OLTheoryIsFormula_p OLTheoryIsFormulaD_p.
