%start_A_star(state([b(4)/b(3), b(3)/b(1), b(1)/p(3), b(2)/b(5), b(5)/p(4)], [p(2),p(1)], [b(4), b(2)]), PathCost, 3, 20).

successor(state(Connections, FreeFields, FreeBlocks), move(Block, NewPlace), 1, 
          state([Block/NewPlace|NewConnections], NewFields2, NewBlocks2)) :-
	find_new_move(state(Connections, FreeFields, FreeBlocks), Block, NewPlace, FreeBlocks),
	update_connections(Connections, Block, OldPlace, NewConnections),
	add_new_field_or_block(OldPlace, FreeFields, FreeBlocks, NewFields, NewBlocks),
	remove_old_field_or_block(NewPlace, NewFields, NewBlocks, NewFields2, NewBlocks2).

find_new_move(state(_, Fields, Blocks), X, NewPlace, [X|_]) :-
	delete(Blocks, X, NewBlocks),
	find_move_for_one_block(Fields, NewBlocks, NewPlace).

find_new_move(State, Block, NewPlace, [_|RestBlocks]) :-
	find_new_move(State, Block, NewPlace, RestBlocks).

find_move_for_one_block(_, Blocks, NewPlace) :-
	get_new_position(Blocks, NewPlace).

find_move_for_one_block(Fields, _, NewPlace) :-
	get_new_position(Fields, NewPlace).

get_new_position([X|_], X).

get_new_position([_|R], X) :-
	get_new_position(R, X).

update_connections([BlockAbove/BlockBelow|RestConnections], BlockAbove, BlockBelow, RestConnections) :- ! .
 
update_connections([FirstBlockAbove/FirstBlockBelow|RestConnections], BlockAbove, 
                   BlockBelow, [FirstBlockAbove/FirstBlockBelow|R2]) :-
	update_connections(RestConnections, BlockAbove, BlockBelow, R2).

add_new_field_or_block(p(X), RestFields, Blocks, [p(X)|RestFields], Blocks).
 
add_new_field_or_block(b(X), RestFields, Blocks, RestFields, [b(X)|Blocks]).

remove_old_field_or_block(p(X), NewFields, NewBlocks, NewFields2, NewBlocks) :-
	del(NewFields, p(X), NewFields2).
 
remove_old_field_or_block(b(X),NewFields,NewBlocks,NewFields,NewBlocks2):-
	del(NewBlocks, b(X), NewBlocks2).

hScore_sum_occurences([], _, 0).

hScore_sum_occurences([FirstElement|RestElements], Array, Result):-
	member(FirstElement, Array), ! ,
	hScore_sum_occurences(RestElements, Array, PartialResult),
	Result is PartialResult + 1.

hScore_sum_occurences([_|RestElements], Array, Result):-
	hScore_sum_occurences(RestElements, Array, Result).

hScore(state(Connections, FreeFields, FreeBlocks), Score):-
	hScore_sum_occurences(Connections, [b(4)/p(1), b(3)/b(1), b(1)/p(3), b(2)/b(5), b(5)/p(4)], PartialScore1),
	hScore_sum_occurences(FreeFields, [p(2)], PartialScore2),
	hScore_sum_occurences(FreeBlocks, [b(4), b(3), b(2)], PartialScore3),
	Score is PartialScore1 + PartialScore2 + PartialScore3.

final_state( state([b(4)/p(1), b(3)/b(1), b(1)/p(3), b(2)/b(5), b(5)/p(4)], 
                   [p(2)], 
                   [b(4), b(3), b(2)]) ).

goal(State) :-
	final_state(FinalState),
	equal_lengths(State, FinalState),
	equal_states(State, FinalState).
   
equal_lengths(state(Connections1, FreeFields1, FreeBlocks1), 
              state(Connections2, FreeFields2, FreeBlocks2)) :-
	equal_length(Connections1, Connections2),
	equal_length(FreeFields1, FreeFields2),
	equal_length(FreeBlocks1, FreeBlocks2).

equal_length([], []).

equal_length([_|Rest1], [_|Rest2]) :-
	equal_length(Rest1, Rest2).

equal_states(state(Connections1, FreeFields1, FreeBlocks1), 
              state(Connections2, FreeFields2, FreeBlocks2)) :-
	equal_lists(Connections1, Connections2),
	equal_lists(FreeFields1, FreeFields2),
	equal_lists(FreeBlocks1, FreeBlocks2).

equal_lists(_, []).

equal_lists([Elem|Rest], List) :-
	member(Elem, List),
	del(List, Elem, NewList),
	equal_lists(Rest, NewList).


start_A_star(InitState, PathCost, N, MaxStepLimit):-
	score(InitState, 0, 0, InitCost, InitScore),
	search_A_star([node(InitState, nil, nil, InitCost , InitScore )], [], PathCost, N, 1, MaxStepLimit).

search_A_star(Queue, ClosedSet, PathCost, N, StepCounter, MaxStepLimit):-
	StepCounter < MaxStepLimit, ! ,
	write("Numer kroku: "),
	write(StepCounter), nl,
	fetch_new(Node, Queue, ClosedSet, RestQueue, N),
	NewStepCounter is StepCounter + 1,
	continue(Node, RestQueue, ClosedSet, PathCost, N, NewStepCounter, MaxStepLimit).

search_A_star(Queue, ClosedSet, PathCost, N, StepCounter, MaxStepLimit):-
	write("Numer kroku: "),
	write(StepCounter), nl,
	output_nodes(Queue, N, ClosedSet, _),
	write('Przekroczono limit krokow. Zwiekszyc limit? (t/n)'), nl,
	read('t'),
	NewLimit is MaxStepLimit + 1,
	fetch_new(Node, Queue, ClosedSet, RestQueue, N),
	NewStepCounter is StepCounter + 1,
	continue(Node, RestQueue, ClosedSet, PathCost, N, NewStepCounter, NewLimit).

continue(node(State, Action, Parent, Cost, _), _, ClosedSet, path_cost(Path, Cost), _, _, _):-
	goal(State),!,
	build_path(node(Parent, _, _, _, _), ClosedSet, [Action/State], Path).

continue(Node, RestQueue, ClosedSet, Path, N, StepCounter, MaxStepLimit):-
	expand(Node, NewNodes),
	insert_new_nodes(NewNodes, RestQueue, NewQueue),
	search_A_star(NewQueue, [Node| ClosedSet], Path, N, StepCounter, MaxStepLimit).

fetch(node(State, Action,Parent, Cost, Score), [node(State, Action,Parent, Cost, Score) |RestQueue], ClosedSet, RestQueue, _):-
	\+ member(node(State, _ ,_  , _ , _ ) , ClosedSet), ! .

fetch(Node, [ _ |RestQueue], ClosedSet, NewRest, N):-
	fetch(Node, RestQueue, ClosedSet , NewRest, N).

output_nodes(_, 0, _, 0):- ! .

output_nodes([], N, _, N).

output_nodes([X|R], N, ClosedSet, N2):-
	member(X, ClosedSet), ! ,
	output_nodes(R, N, ClosedSet, N2).

output_nodes([X|R], N, ClosedSet, N2):-
	write(X), nl,
	NewN is N - 1,
	output_nodes(R, NewN, ClosedSet, N2).

input_decisions(0, []):- ! .

input_decisions(N, [D|RestDecisions]):-
	read(D),
	NewN is N - 1,
	input_decisions(NewN, RestDecisions).

get_user_decisions(Queue, N, ClosedSet, Decisions):-
	output_nodes(Queue, N, ClosedSet, Diff),
	write('Wybierz indeksy: '), nl,
	NewN is N - Diff,
	input_decisions(NewN, Decisions).

get_index_nondeterministic(X, [X|_]).

get_index_nondeterministic(X, [_|R]):-
	get_index_nondeterministic(X, R).

get_element_at_index(1, X, [X|R], ClosedSet, R):-
	\+ member(X, ClosedSet), ! .

get_element_at_index(Index, Node, [X|R], ClosedSet,[X|RestQueue]):-
	\+ member(X, ClosedSet), ! ,
	NewIndex is Index - 1,
	get_element_at_index(NewIndex, Node, R, ClosedSet, RestQueue).

get_element_at_index(Index, Node, [X|R], ClosedSet, [X|RestQueue]):-
	get_element_at_index(Index, Node, R, ClosedSet, RestQueue).

fetch_new(Node, Queue, ClosedSet, RestQueue, N):-
	get_user_decisions(Queue, N, ClosedSet, Decisions),
	get_index_nondeterministic(Index, Decisions),
	get_element_at_index(Index, Node, Queue, ClosedSet, RestQueue).

expand(node(State, _ ,_ , Cost, _ ), NewNodes):-
	findall(node(ChildState, Action, State, NewCost, ChildScore),
%			(succ(State, Action, StepCost, ChildState), score(ChildState, Cost, StepCost, NewCost, ChildScore)),
			(successor(State, Action, StepCost, ChildState), score(ChildState, Cost, StepCost, NewCost, ChildScore)),
			NewNodes), ! .

score(State, ParentCost, StepCost, Cost, FScore):-
	Cost is ParentCost + StepCost,
	hScore(State, HScore),
	FScore is Cost - HScore.
%	FScore is Cost + HScore.

insert_new_nodes( [ ], Queue, Queue) .

insert_new_nodes( [Node|RestNodes], Queue, NewQueue):-
	insert_p_queue(Node, Queue, Queue1),
	insert_new_nodes( RestNodes, Queue1, NewQueue) .

insert_p_queue(Node,  [ ], [Node] ):- ! .

insert_p_queue(node(State, Action, Parent, Cost, FScore),
		[node(State1, Action1, Parent1, Cost1, FScore1)|RestQueue],
		[node(State1, Action1, Parent1, Cost1, FScore1)|Rest1] ):-
	FScore >= FScore1, ! ,
	insert_p_queue(node(State, Action, Parent, Cost, FScore), RestQueue, Rest1).

insert_p_queue(node(State, Action, Parent, Cost, FScore), Queue, [node(State, Action, Parent, Cost, FScore)|Queue]).

build_path(node(nil, _, _, _, _ ), _, Path, Path):- ! .

build_path(node(EndState, _ , _ , _, _ ), Nodes, PartialPath, Path):-
	del(Nodes, node(EndState, Action, Parent , _ , _  ) , Nodes1) ,
	build_path(node(Parent,_ ,_ , _ , _ ) , Nodes1, [Action/EndState|PartialPath],Path).

del([X|R],X,R).

del([Y|R],X,[Y|R1]):-
	X\=Y,
	del(R,X,R1).