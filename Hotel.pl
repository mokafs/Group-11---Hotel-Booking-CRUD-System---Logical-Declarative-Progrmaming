:- use_module(library(odbc)).

% Establish a connection to the MySQL database
connect_to_mysql(Connection) :-
    odbc_connect('hotemanagement', Connection, [user('root'), password('')]).

test_connect(Connection) :-
    odbc_connect('hotemanagement', Connection, [user('root'), password('')]),
    write('Connection Succesful!').

guest_exists(Connection, Guest_name) :-
    format(atom(Query), 'SELECT Guest_Name FROM guest WHERE Guest_Name = \'~w\'', [Guest_name]),
    odbc_query(Connection, Query, row(_)).

date_exists(Connection, Room_ID, Check_In, Check_Out) :-
    format(atom(Query), 'SELECT Check_In, Check_Out
    FROM booking
    WHERE Room_ID = ~d
    AND (
        \'~w\' < Check_Out AND
        \'~w\' > Check_In
    );', [Room_ID, Check_In, Check_Out]),
    odbc_query(Connection, Query, row(_, _)).

guest_id_exists(Connection, Guest_ID) :-
    format(atom(Query), 'SELECT Guest_ID FROM guest WHERE Guest_ID = ~d', [Guest_ID]),
    odbc_query(Connection, Query, row(_)).

booking_id_exists(Connection, Booking_ID) :-
    format(atom(Query), 'SELECT Booking_ID FROM booking WHERE Booking_ID = ~d', [Booking_ID]),
    odbc_query(Connection, Query, row(_)).

room_id_exists(Connection, Room_ID) :-
    format(atom(Query), 'SELECT Room_ID FROM room WHERE Room_ID = ~d', [Room_ID]),
    odbc_query(Connection, Query, row(_)).

guest_delete_check(Connection, Guest_ID) :-
    format(atom(Query), 'SELECT Guest_ID FROM booking WHERE Guest_ID = ~d', [Guest_ID]),
    odbc_query(Connection, Query, row(_)).

room_delete_check(Connection, Room_ID) :-
    format(atom(Query), 'SELECT Room_ID FROM booking WHERE Room_ID = ~d', [Room_ID]),
    odbc_query(Connection, Query, row(_)).

% CREATE---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
create_booking_n(Connection, Room_ID, Guest_ID, Reservation_Status, Payment_ID, Check_in, Check_out) :-
    % Retrieve the next auto-increment value for booking_ID
    odbc_query(Connection, 'SELECT MAX(booking_ID) AS max_id FROM booking', row(MaxID)),
    NewID is MaxID + 1,
    format(atom(Query), 'INSERT INTO booking (Booking_ID, Room_ID, Guest_ID, Reservation_Status, Payment_ID, Check_in, Check_out) VALUES (~d, ~d, ~d, ~d, ~d, \'~w\', \'~w\')', 
    [NewID, Room_ID, Guest_ID, Reservation_Status, Payment_ID, Check_in, Check_out]),
    odbc_query(Connection, Query, _).

create_guest_n(Connection, Guest_Name, Guest_Gender, Guest_Contact, Guest_Email) :-
    % Retrieve the next auto-increment value for booking_ID
    odbc_query(Connection, 'SELECT MAX(Guest_ID) AS max_id FROM guest', row(MaxID)),
    NewID is MaxID + 1,
    format(atom(Query), 'INSERT INTO guest (Guest_ID, Guest_Name, Guest_Gender, Guest_Contact, Guest_Email) VALUES (~d, \'~w\', \'~w\', ~d, \'~w\')', 
    [NewID, Guest_Name, Guest_Gender, Guest_Contact, Guest_Email]),
    odbc_query(Connection, Query, _).
    
create_booking_interactively :-
    % Establish connection to the database
    connect_to_mysql(Connection),
    
    % Display available rooms
    format('Rooms:~n'),
    display_all_rooms(Connection),
    
    % Prompt user for room ID
    repeat,
    format('Enter Room ID: '), read(Room_ID),
    (   
        room_id_exists(Connection, Room_ID)
        ->  
        true % Room ID exists
    ; 
        writeln('Error: Room ID does not exist in the database. Please enter a different ID.'),
        fail % Retry input
    ),
    
    % Display available guests
    format('Guests:~n'),
    display_available_guests(Connection),
    
    % Prompt user for guest ID
    format('Enter Guest ID: '), read(Guest_ID),
    
    % Prompt user for other booking details
    display_reservation_status(Connection),
    format('Enter Reservation Status: '), read(Reservation_Status),
    display_payment_types(Connection),
    format('Enter Payment ID: '), read(Payment_ID),
    
    % Prompt user for Check-in and Check-out dates
    repeat,
    format('Enter Check-in Date (yyyy-mm-dd): '), read(Check_in),
    format('Enter Check-out Date (yyyy-mm-dd): '), read(Check_out),
    (   Check_in @< Check_out ->
        % Check_in date is before Check_out date
        (   date_exists(Connection, Room_ID, Check_in, Check_out) ->
            writeln('Error: There is an existing booking that overlaps with the provided dates. Please try again.'),
            fail
        ;   true
        )
    ;   % Check_in date is after Check_out date
        writeln('Error: Check-in date cannot be after Check-out date. Please try again.'),
        fail
    ),

    % Create booking using the provided details
    create_booking_n(Connection, Room_ID, Guest_ID, Reservation_Status, Payment_ID, Check_in, Check_out),
    odbc_disconnect(Connection).
    
create_guest_interactively :-
    connect_to_mysql(Connection),
    % Prompt for Guest Name and read the input
    repeat,
    format('Enter guest name: '), read(Guest_Name),
    (   guest_exists(Connection, Guest_Name) ->
        writeln('Error: Guest name already exists in the database. Please enter a different name.'),
        fail % Loop back to re-prompt for guest name
    ; 
        !
    ),

    % Prompt for Guest Gender and read the input
    repeat,
    format('Enter Guest gender: '), read(Guest_Gender),
    (   (Guest_Gender = 'Male' ; Guest_Gender = 'Female') 
        
    ;   
        writeln('Error: Invalid gender. Please enter Male or Female.'),
        fail
    ),
          
    % Prompt for Guest Contact Number and read the input
    repeat,
    format('Enter Guest Mobile Contact Number (9-digits): '), read(Guest_Contact),
    (   integer(Guest_Contact),
            Guest_Contact >= 0,
            number_chars(Guest_Contact, ContactChars),
            length(ContactChars, 9)
            ->  true % Valid contact number input
        ;   
            writeln('Error: Invalid contact number. Please enter an 9-digit number.'),
            fail
        ),
          
    % Prompt for Guest Email and read the input
    format('Enter Guest Email: '), read(Guest_Email),
          
    % Call the create_guest_n function with the obtained values
    create_guest_n(Connection, Guest_Name, Guest_Gender, Guest_Contact, Guest_Email),
    odbc_disconnect(Connection).

% CREATE ROOM
create_room_interactively :-
    connect_to_mysql(Connection),
    display_room_types(Connection),
    format('Enter Room_Type: '), read(Room_Type),
          
    
    format('Enter Room Rates: '), read(Room_Rate),
        
    
    create_room_n(Connection, Room_Type, Room_Rate),
    odbc_disconnect(Connection).

create_room_n(Connection, Room_Type, Room_Rate) :-
    % Retrieve the next auto-increment value for booking_ID
    odbc_query(Connection, 'SELECT MAX(Room_ID) AS max_id FROM room', row(MaxID)),
    NewID is MaxID + 1,
    format(atom(Query), 'INSERT INTO room (Room_ID, Room_Type, Room_Rate) VALUES (~d, ~d, ~d)', 
    [NewID, Room_Type, Room_Rate]),
    odbc_query(Connection, Query, _).

% READ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

% READS ALL BOOKINGS
display_all_bookings :-
    connect_to_mysql(Connection),
    display_all_bookings(Connection),
    odbc_disconnect(Connection).

% Predicate to fetch and display all rows
display_all_bookings(Connection) :-
    odbc_query(Connection,
               'SELECT b.booking_ID, r.Room_ID, rt.Type, g.Guest_Name, s.Status, pt.Type, b.Check_In, b.Check_Out
                FROM booking b
                INNER JOIN room r ON b.Room_ID = r.Room_ID
                INNER JOIN room_type rt ON r.Room_Type = rt.Room_TypeID
                INNER JOIN guest g ON b.Guest_ID = g.Guest_ID
                INNER JOIN status s ON b.Reservation_Status = s.Status_ID
                INNER JOIN payment_type pt ON b.Payment_ID = pt.Type_ID',
               Row), % Fetch a row

    % If Row is not unified, the predicate fails, terminating the loop
    display_booking(Row),

    % Retry the query to fetch the next row (failure-driven loop)
    false.

% Base case for the recursion (no more rows to fetch)
display_all_bookings(_).

% Predicate to display a single booking
display_booking(row(BookingID, Room_ID, RoomType, GuestName, ReservationStatus, PaymentType, CheckIn, CheckOut)) :-
    % Display the fetched row
    format('\nBooking ID: ~w \nRoom_ID: ~w \nRoom Type: ~w \nGuest Name: ~w \nReservation Status: ~w \nPayment Type: ~w \nCheck-In: ~w \nCheck-Out: ~w~n \n',
           [BookingID, Room_ID, RoomType, GuestName, ReservationStatus, PaymentType, CheckIn, CheckOut]).

% READS ALL GUESTS
display_all_guests :-
    connect_to_mysql(Connection),
    display_all_guests(Connection),
    odbc_disconnect(Connection).

% Predicate to fetch and display all rows
display_all_guests(Connection) :-
    odbc_query(Connection,
               'SELECT * FROM guest',
               Row), % Fetch a row

    % If Row is not unified, the predicate fails, terminating the loop
    display_guests(Row),

    % Retry the query to fetch the next row (failure-driven loop)
    false.

% Base case for the recursion (no more rows to fetch)
display_all_guests(_).

% Predicate to display a single booking
display_guests(row(GuestID, GuestName, GuestGender, GuestContact, GuestEmail)) :-
    % Display the fetched row
    format('\nGuest ID: ~w \nName: ~w \nGender: ~w \nContact: ~w \nEmail: ~w \n\n',
           [GuestID, GuestName, GuestGender, GuestContact, GuestEmail]).


% READS ALL ROOMS
display_all_rooms :-
    connect_to_mysql(Connection),
    display_all_rooms(Connection),
    odbc_disconnect(Connection).

% Predicate to fetch and display all rows
display_all_rooms(Connection) :-
    odbc_query(Connection,
               'SELECT r.Room_ID, rt.Type, r.Room_Rate FROM room r
                INNER JOIN room_type rt ON r.Room_Type=rt.Room_TypeID',
                Row), % Fetch a row

    % If Row is not unified, the predicate fails, terminating the loop
    display_rooms(Row),

    % Retry the query to fetch the next row (failure-driven loop)
    false.

% Base case for the recursion (no more rows to fetch)
display_all_rooms(_).

% Predicate to display a single booking
display_rooms(row(RoomID, Type, RoomRate)) :-
    % Display the fetched row
    format('\nRoom ID: ~w \nType: ~w \nRoom Rate: ~w \n\n',
           [RoomID, Type, RoomRate]).

% Predicate to display available rooms
display_available_rooms(Connection) :-
    odbc_query(Connection, 'SELECT Room_ID FROM room', row(Room_ID)),
    format('\n~w~n\n', [Room_ID]),
    fail.
display_available_rooms(_).

display_available_guests(Connection) :-
    odbc_query(Connection, 'SELECT Guest_ID, Guest_Name FROM guest', row(Guest_ID, Guest_Name)),
    format('\n~w: ~w~n\n', [Guest_ID, Guest_Name]),
    fail.
display_available_guests(_).

display_payment_types :-
    connect_to_mysql(Connection),
    display_payment_types(Connection),
    odbc_disconnect(Connection).

display_payment_types(Connection) :-
    odbc_query(Connection, 'SELECT Type_ID, Type FROM payment_type', row(Type_ID, Type)),
    format('\n~w: ~w~n\n', [Type_ID, Type]),
    fail.
display_payment_types(_).

display_reservation_status :-
    connect_to_mysql(Connection),
    display_reservation_status(Connection),
    odbc_disconnect(Connection).

display_reservation_status(Connection) :-
    odbc_query(Connection, 'SELECT Status_ID, Status FROM status', row(Status_ID, Status)),
    format('\n~w: ~w~n\n', [Status_ID, Status]),
    fail.
display_reservation_status(_).

display_room_types :-
    connect_to_mysql(Connection),
    display_room_types(Connection),
    odbc_disconnect(Connection).

display_room_types(Connection) :-
    odbc_query(Connection, 'SELECT Room_TypeID, Type FROM room_type', row(RtypeID, Rtype)),
    format('\n~w: ~w~n\n', [RtypeID, Rtype]),
    fail.
display_room_types(_).

% UPDATE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

% UPDATE BOOKING
update_booking(Connection, Booking_ID, Guest_ID, Room_ID, Reservation_Status, Payment_ID, Check_In, Check_Out) :-
    % Prepare the SQL statement for updating the booking
    ground([Connection, Booking_ID]),
    % Initialize the list of clauses
    Clauses = [],

    % Add clauses for attributes with non-empty values
    (non_empty(Guest_ID) ->
        clause(Guest_ID, 'Guest_ID', GuestClause),
        append(Clauses, [GuestClause], UpdatedClauses)
    ; UpdatedClauses = Clauses
    ),
    (non_empty(Room_ID) ->
        clause(Room_ID, 'Room_ID', RoomClause),
        append(UpdatedClauses, [RoomClause], UpdatedClauses2)
    ; UpdatedClauses2 = UpdatedClauses
    ),
    (non_empty(Reservation_Status) ->
        clause(Reservation_Status, 'Reservation_Status', StatusClause),
        append(UpdatedClauses2, [StatusClause], UpdatedClauses3)
    ; UpdatedClauses3 = UpdatedClauses2
    ),
    (non_empty(Payment_ID) ->
        clause(Payment_ID, 'Payment_ID', PaymentClause),
        append(UpdatedClauses3, [PaymentClause], UpdatedClauses4)
    ; UpdatedClauses4 = UpdatedClauses3
    ),
    (non_empty(Check_In) ->
        clause(Check_In, 'Check_In', CheckInClause),
        append(UpdatedClauses4, [CheckInClause], UpdatedClauses5)
    ; UpdatedClauses5 = UpdatedClauses4
    ),
    (non_empty(Check_Out) ->
        clause(Check_Out, 'Check_Out', CheckOutClause),
        append(UpdatedClauses5, [CheckOutClause], UpdatedClauses6)
    ; UpdatedClauses6 = UpdatedClauses5
    ),

    % Construct the final SQL query
    atomic_list_concat(UpdatedClauses6, ', ', ClausesString),
    format(atom(Query),
           'UPDATE booking 
            SET ~w
            WHERE booking_ID = ~d',
           [ClausesString, Booking_ID]),

    % Execute the SQL statement
    odbc_query(Connection, Query, _).


    update_booking_interactively :-
        connect_to_mysql(Connection),
        display_all_bookings(Connection),
        repeat,
        format('Which booking would you want updated?(Enter BookingID): '), read(Booking_ID),
        (   
            booking_id_exists(Connection, Booking_ID)
            ->  
            true % Booking ID exists
        ; 
            writeln('Error: Booking ID does not exist in the database. Please enter a different ID.'),
            fail % Retry input
        ),
    
        % Prompt for update mode
        format('Update mode: (1) Update all attributes, (2) Selective update: '), read(UpdateMode),
    
        (UpdateMode =:= 1 ->
            % Update all attributes
            update_booking_all_attributes(Booking_ID, Connection)
        ; UpdateMode =:= 2 ->
            % Selective update
            update_booking_selective_attributes(Booking_ID, Connection)
        ; 
            % Invalid input
            writeln('Invalid update mode selected.')
        ),
    
        odbc_disconnect(Connection).
    
    % Update all attributes for the booking
    update_booking_all_attributes(Booking_ID, Connection) :-
        display_available_guests(Connection),
        repeat,
        format('Update Guest ID: '), read(Guest_ID),
        (   
            guest_id_exists(Connection, Guest_ID)
        ->  
            true % Guest ID exists
        ; 
            writeln('Error: Guest ID does not exist in the database. Please enter a different ID.'),
            fail % Retry input
        ),
        display_all_rooms(Connection),
        repeat,
        format('Update Room ID: '), read(Room_ID),
        (   
            room_id_exists(Connection, Room_ID)
            ->  
            true % Room ID exists
        ; 
            writeln('Error: Room ID does not exist in the database. Please enter a different ID.'),
            fail % Retry input
        ),
        display_reservation_status(Connection),
        format('Update Reservation Status: '), read(Reservation_Status),
        display_payment_types(Connection),
        format('Update Payment ID: '), read(Payment_ID),
        repeat,
        format('Enter Check-in Date (yyyy-mm-dd): '), read(Check_In),
        format('Enter Check-out Date (yyyy-mm-dd): '), read(Check_Out),
        (   Check_In @< Check_Out ->
            % Check_in date is before Check_out date
            (   date_exists(Connection, Room_ID, Check_In, Check_Out) ->
                writeln('Error: There is an existing booking that overlaps with the provided dates. Please try again.'),
                fail
            ;       true
            )
        ;   % Check_in date is after Check_out date
            writeln('Error: Check-in date cannot be after Check-out date. Please try again.'),
            fail
        ),
        update_booking(Connection, Booking_ID, Guest_ID, Room_ID, Reservation_Status, Payment_ID, Check_In, Check_Out).
    
    % Selective update for the booking
    update_booking_selective_attributes(Booking_ID, Connection) :-
        format('Update Guest ID? (y/n): '), read(UpdateGuestID),
        format('Update Room ID? (y/n): '), read(UpdateRoomID),
        format('Update Reservation Status? (y/n): '), read(UpdateReservationStatus),
        format('Update Payment ID? (y/n): '), read(UpdatePaymentID),
        format('Update Check-in Date? (y/n): '), read(UpdateCheckIn),
        format('Update Check-out Date? (y/n): '), read(UpdateCheckOut),
        
        % Read values for attributes to be updated
        repeat,
        (UpdateGuestID == 'y' -> display_available_guests(Connection), format('Update Guest ID: '), read(Guest_ID) ; true),
        (   
            guest_id_exists(Connection, Guest_ID)
        ->  
            true % Guest ID exists
        ; 
            writeln('Error: Guest ID does not exist in the database. Please enter a different ID.'),
            fail % Retry input
        ),
        repeat,
        (UpdateRoomID == 'y' -> display_all_rooms(Connection), format('Update Room ID: '), read(Room_ID) ; true),
        (   
            room_id_exists(Connection, Room_ID)
            ->  
            true % Room ID exists
        ; 
            writeln('Error: Room ID does not exist in the database. Please enter a different ID.'),
            fail % Retry input
        ),
        (UpdateReservationStatus == 'y' -> display_reservation_status(Connection), format('Update Reservation Status: '), read(Reservation_Status) ; true),
        (UpdatePaymentID == 'y' -> display_payment_types(Connection), format('Update Payment ID: '), read(Payment_ID) ; true),
        (UpdateCheckIn == 'y' -> format('Update Check-in Date: '), read(Check_In) ; true),
        (UpdateCheckOut == 'y' -> format('Update Check-out Date: '), read(Check_Out) ; true),
    
        % Call the update_booking function with the obtained values
        update_booking(Connection, Booking_ID, Guest_ID, Room_ID, Reservation_Status, Payment_ID, Check_In, Check_Out).         

% UPDATE GUEST
update_guest(Connection, Guest_ID, Guest_Name, Guest_Gender, Guest_Contact, Guest_Email) :-
    % Prepare the SQL statement for updating the guest
    ground([Connection, Guest_ID]),
    % Initialize the list of clauses
    Clauses = [],

    % Add clauses for attributes with non-empty values
    (   non_empty(Guest_Name) ->
        clause(Guest_Name, 'Guest_Name', NameClause),
        append(Clauses, [NameClause], UpdatedClauses)
    ;   UpdatedClauses = Clauses
    ),
    (   non_empty(Guest_Gender) ->
        clause(Guest_Gender, 'Guest_Gender', GenderClause),
        append(UpdatedClauses, [GenderClause], UpdatedClauses2)
    ;   UpdatedClauses2 = UpdatedClauses
    ),
    (   non_empty(Guest_Contact) ->
        clause(Guest_Contact, 'Guest_Contact', ContactClause),
        append(UpdatedClauses2, [ContactClause], UpdatedClauses3)
    ;   UpdatedClauses3 = UpdatedClauses2
    ),
    (   non_empty(Guest_Email) ->
        clause(Guest_Email, 'Guest_Email', EmailClause),
        append(UpdatedClauses3, [EmailClause], UpdatedClauses4)
    ;   UpdatedClauses4 = UpdatedClauses3
    ),

    % Construct the final SQL query
    atomic_list_concat(UpdatedClauses4, ', ', ClausesString),
    format(atom(Query),
           'UPDATE guest 
            SET ~w
            WHERE Guest_ID = ~d',
           [ClausesString, Guest_ID]),

    % Execute the SQL statement
    odbc_query(Connection, Query, _).

% Helper predicate to check if a value is non-empty
non_empty(Value) :-
    Value \= ''.

% Helper predicate to construct a clause for a non-empty value
clause(Value, Name, Clause) :-
    format(atom(Clause), '~w = \'~w\'', [Name, Value]).



update_guest_interactively :-
    connect_to_mysql(Connection),
    display_available_guests(Connection),
    
    repeat,
    format('Which Guest would you want to update? : '), 
    read(Guest_ID),
    (   
        guest_id_exists(Connection, Guest_ID)
    ->  
        true % Guest ID exists
    ; 
        writeln('Error: Guest ID does not exist in the database. Please enter a different ID.'),
        fail % Retry input
    ),
        
    % Prompt user to select update mode
    format('Update mode: (1) Update all attributes, (2) Selective update: '), read(UpdateMode),
    
    (UpdateMode =:= 1 ->
        % Update all attributes
        repeat,
        format('Update Name with? : '), read(Guest_Name),
        (   guest_exists(Connection, Guest_Name) ->
        writeln('Error: Guest name already exists in the database. Please enter a different name.'),
        fail % Loop back to re-prompt for guest name
        ; 
            !
        ),
        repeat,
        format('Update Gender? : '), read(Guest_Gender),
        (   (Guest_Gender = 'Male' ; Guest_Gender = 'Female') 
        
        ;   
            writeln('Error: Invalid gender. Please enter Male or Female.'),
            fail
        ),
        repeat,
        format('Update Contact? : '), read(Guest_Contact),
        (   integer(Guest_Contact),
            Guest_Contact >= 0,
            number_chars(Guest_Contact, ContactChars),
            length(ContactChars, 9)
            ->  true % Valid contact number input
        ;   
            writeln('Error: Invalid contact number. Please enter an 9-digit number.'),
            fail
        ),
        format('Update Email? : '), read(Guest_Email)
    ; UpdateMode =:= 2 ->
        % Selective update
        repeat,
        format('Update Name? (y/n): '), read(UpdateName),
        (   guest_exists(Connection, UpdateName) ->
        writeln('Error: Guest name already exists in the database. Please enter a different name.'),
        fail % Loop back to re-prompt for guest name
        ; 
            !
        ),
        format('Update Gender? (y/n): '), read(UpdateGender),
        format('Update Contact? (y/n): '), read(UpdateContact),
        format('Update Email? (y/n): '), read(UpdateEmail),
    
        % Read values for attributes to be updated
        (UpdateName == 'y' -> format('Update Name with? : '), read(Guest_Name) ; true),
        repeat,
        (UpdateGender == 'y' -> format('Update Gender? : '), read(Guest_Gender) ; true),
        (   (Guest_Gender = 'Male' ; Guest_Gender = 'Female') 
        
        ;   
            writeln('Error: Invalid gender. Please enter Male or Female.'),
            fail
        ),
        repeat,
        (UpdateContact == 'y' -> format('Update Contact? : '), read(Guest_Contact) ; true),
        (   integer(Guest_Contact),
            Guest_Contact >= 0,
            number_chars(Guest_Contact, ContactChars),
            length(ContactChars, 9)
    
        ->  true % Valid contact number input
        ;   
            writeln('Error: Invalid contact number. Please enter an 9-digit number.'),
            fail
        ),
        (UpdateEmail == 'y' -> format('Update Email? : '), read(Guest_Email) ; true)
    ; 
        % Invalid input
        writeln('Invalid update mode selected.'),
        odbc_disconnect(Connection),
        fail
    ),
    
    % Call the update_guest predicate with the obtained values
    update_guest(Connection, Guest_ID, Guest_Name, Guest_Gender, Guest_Contact, Guest_Email),
    odbc_disconnect(Connection).

% UPDATE ROOM
update_room(Connection, Room_ID, Room_Type, Room_Rate) :-
    % Prepare the SQL statement for updating the room
    ground([Connection, Room_ID]),
    % Initialize the list of clauses
    Clauses = [],

    % Add clauses for attributes with non-empty values
    (   non_empty(Room_Type) ->
        clause(Room_Type, 'Room_Type', TypeClause),
        append(Clauses, [TypeClause], UpdatedClauses)
    ;   UpdatedClauses = Clauses
    ),
    (   non_empty(Room_Rate) ->
        clause(Room_Rate, 'Room_Rate', RateClause),
        append(UpdatedClauses, [RateClause], UpdatedClauses2)
    ;   UpdatedClauses2 = UpdatedClauses
    ),

    % Check if there are any attributes to update
    (   UpdatedClauses2 \== [] ->
        % Construct the final SQL query
        atomic_list_concat(UpdatedClauses2, ', ', ClausesString),
        format(atom(Query),
               'UPDATE room 
                SET ~w
                WHERE Room_ID = ~d',
               [ClausesString, Room_ID]),
        
        % Execute the SQL statement
        odbc_query(Connection, Query, _)
    ;   true % No attributes to update
    ).
    
update_room_interactively :-
    connect_to_mysql(Connection),
            
    display_all_rooms(Connection),
    format('Which room would you want to be updated? : '), read(Room_ID),
            
    format('Update mode: (1) Update all attributes, (2) Selective update: '), read(UpdateMode),
        
    (UpdateMode =:= 1 ->
        % Update all attributes
        display_room_types(Connection),
        format('Update Room Type? : '), read(Room_Type),
                          
        % Prompt for room rate and read the input
        format('Update Rates? : '), read(Room_Rate),
        update_room(Connection, Room_ID, Room_Type, Room_Rate)
    ; UpdateMode =:= 2 ->
        % Selective update
        format('Update Room Type? (y/n): '), read(UpdateRoomType),
        format('Update Rates? (y/n): '), read(UpdateRoomRate),
        
        % Initialize variables
        UpdatedRoomType = Room_Type,
        UpdatedRoomRate = Room_Rate,
        
        % Apply selective updates
        (UpdateRoomType == 'y' -> display_room_types(Connection), format('Update Room Type: '), read(UpdatedRoomType) ; true),
        (UpdateRoomRate == 'y' -> format('Update Rates: '), read(UpdatedRoomRate) ; true),
        
        update_room(Connection, Room_ID, UpdatedRoomType, UpdatedRoomRate)
    ; 
        % Invalid input
        writeln('Invalid update mode selected.')
    ),
    odbc_disconnect(Connection).
    
% DELETE-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

% DELETE BOOKING
delete_booking(Connection, Booking_ID) :-
    format(atom(Query),
           'DELETE FROM booking WHERE Booking_ID = ~d',
           [Booking_ID]),
    odbc_query(Connection, Query, _).

delete_booking_interactively :-
    connect_to_mysql(Connection),
    
    display_all_bookings(Connection),
    
    format('Which Booking would you want to delete? : '), read(Booking_ID),
        
    delete_booking(Connection, Booking_ID),
    odbc_disconnect(Connection).

% DELETE GUEST
delete_guest(Connection, Guest_ID) :-
    format(atom(Query),
           'DELETE FROM guest WHERE Guest_ID = ~d',
           [Guest_ID]),
    odbc_query(Connection, Query, _).

delete_guest_interactively :-
    connect_to_mysql(Connection),
    
    display_all_guests(Connection),
    repeat,
    format('Which Guest would you want to delete? : '), read(Guest_ID),
    (   
        guest_id_exists(Connection, Guest_ID)
        ->  
        true % Guest ID exists
    ; 
        writeln('Error: Guest ID does not exist in the database. Please enter a different ID.'),
        fail % Retry input
    ),
        
    (   guest_delete_check(Connection, Guest_ID)
    ->  % Room has bookings
        writeln('This guest has bookings. Deleting it will also delete associated bookings.'),
        format('Are you sure you want to delete this guest? (y/n): '), read(Confirmation),
        (   Confirmation = 'y'
        ->  % User confirmed deletion
            delete_guest(Connection, Guest_ID),
            writeln('Room deleted successfully.')
        ;   % User declined deletion
            writeln('Room deletion aborted.')
        )
    ;   % Room has no bookings
        delete_room(Connection, Guest_ID),
        writeln('Room deleted successfully.')
    ),
    odbc_disconnect(Connection).

% DELETE ROOM
delete_room(Connection, Room_ID) :-
    format(atom(Query),
           'DELETE FROM room WHERE Room_ID = ~d',
           [Room_ID]),
    odbc_query(Connection, Query, _).

delete_room_interactively :-
    connect_to_mysql(Connection),
    
    display_all_rooms(Connection),
    repeat,
    format('Which room would you want to delete? : '), read(Room_ID),
    (   
        room_id_exists(Connection, Room_ID)
        ->  
        true % Room ID exists
    ; 
        writeln('Error: Room ID does not exist in the database. Please enter a different ID.'),
        fail % Retry input
    ),
        
    (   room_delete_check(Connection, Room_ID)
    ->  % Room has bookings
        writeln('This room has bookings. Deleting it will also delete associated bookings.'),
        format('Are you sure you want to delete this room? (y/n): '), read(Confirmation),
        (   Confirmation = 'y'
        ->  % User confirmed deletion
            delete_room(Connection, Room_ID),
            writeln('Room deleted successfully.')
        ;   % User declined deletion
            writeln('Room deletion aborted.')
        )
    ;   % Room has no bookings
        delete_room(Connection, Room_ID),
        writeln('Room deleted successfully.')
    ),
    odbc_disconnect(Connection).

% Example usage:
% display_all_rooms/guests/rooms.
% create_booking/guest/room_interactively.    
main:-
    writeln('This is a Hotel Booking CRUD System!'),
    writeln('CREATE predicates-------------'),
    writeln('create_booking_interactively\ncreate_guest_interactively\ncreate_room_interactively'),
    writeln('READ predicates----------------'),
    writeln('display_all_bookings\ndisplay_all_guests\ndisplay_all_rooms\ndisplay_payment_types\ndisplay_reservation_status\ndisplay_room_types'),
    writeln('UPDATE predicates-------------'),
    writeln('update_booking_interactively\nupdate_guest_interactively\nupdate_room_interactively'),
    writeln('DELETE predicates--------------'),
    writeln('delete_booking_interactively\ndelete_guest_interactively\ndelete_room_interactively').
