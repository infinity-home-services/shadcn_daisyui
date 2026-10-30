defmodule ShadcnDaisyui.DataTable.StateTest do
  use ExUnit.Case, async: true

  alias ShadcnDaisyui.DataTable.State

  doctest State

  @opts [
    filters: %{"status" => "any", "owner" => "any", "stage" => "open"},
    sorts: ~w(number total placed)
  ]

  describe "URL params" do
    test "from_params reads the search, sort, direction and filters" do
      state =
        State.from_params(
          %{"q" => "  riverside ", "sort" => "total", "dir" => "desc", "status" => "open,paid"},
          @opts
        )

      assert state.search == "riverside"
      assert state.sort == "total"
      assert state.dir == :desc
      assert state.filters == %{"status" => "open,paid", "owner" => "any", "stage" => "open"}
      assert state.selected == MapSet.new()
      assert state.anchor == nil
    end

    test "missing and empty params are the defaults" do
      assert State.from_params(%{}, @opts) == %State{
               filters: %{"status" => "any", "owner" => "any", "stage" => "open"}
             }

      assert State.from_params(nil, @opts).filters["stage"] == "open"
      assert State.from_params(%{"status" => ""}, @opts).filters["status"] == "any"
    end

    test "a filter can arrive as a list (status[]=a&status[]=b)" do
      assert State.from_params(%{"status" => ["open", "", "paid"]}, @opts).filters["status"] ==
               "open,paid"
    end

    test "an unknown sort key is ignored, and dir needs a sort" do
      assert %State{sort: nil, dir: :asc} =
               State.from_params(%{"sort" => "secret", "dir" => "desc"}, @opts)

      assert %State{sort: nil, dir: :asc} = State.from_params(%{"dir" => "desc"}, @opts)
    end

    test "without sorts, any key sorts" do
      assert State.from_params(%{"sort" => "anything"}, []).sort == "anything"
    end

    test "to_params leaves out what's at its default" do
      assert State.to_params(State.from_params(%{}, @opts), @opts) == %{}

      state = %State{
        search: "pat",
        sort: "number",
        dir: :asc,
        filters: %{"status" => "open", "owner" => "any", "stage" => "open"}
      }

      assert State.to_params(state, @opts) == %{
               "q" => "pat",
               "sort" => "number",
               "status" => "open"
             }
    end

    test "to_params keeps a filter moved off a real default, and dir=desc" do
      state = %State{
        sort: "total",
        dir: :desc,
        filters: %{"status" => "any", "owner" => "any", "stage" => "won,lost"}
      }

      assert State.to_params(state, @opts) == %{
               "sort" => "total",
               "dir" => "desc",
               "stage" => "won,lost"
             }
    end

    test "round trip: from_params(to_params(state)) is the same state" do
      for params <- [
            %{},
            %{"q" => "blue harbor"},
            %{"sort" => "placed", "dir" => "desc"},
            %{"status" => "open,paid", "owner" => "pat", "stage" => "won"},
            %{"q" => "x", "sort" => "number", "status" => "refunded"}
          ] do
        state = State.from_params(params, @opts)
        assert State.from_params(State.to_params(state, @opts), @opts) == state
        assert State.to_params(state, @opts) == params
      end
    end

    test "the selection never goes into the URL" do
      state = State.from_params(%{"q" => "a"}, @opts) |> State.select("1")
      assert State.to_params(state, @opts) == %{"q" => "a"}
    end
  end

  describe "filters" do
    test "filtered? is the search or any filter off its default" do
      refute State.filtered?(State.from_params(%{}, @opts), @opts)
      assert State.filtered?(State.from_params(%{"q" => "a"}, @opts), @opts)
      assert State.filtered?(State.from_params(%{"status" => "open"}, @opts), @opts)
      assert State.filtered?(State.from_params(%{"stage" => "won"}, @opts), @opts)
      refute State.filtered?(State.from_params(%{"stage" => "open"}, @opts), @opts)
    end

    test "values splits a comma list; any, empty and nil are none" do
      assert State.values("open") == ["open"]
      assert State.values("open, paid") == ["open", "paid"]
      assert State.values(["open", "paid"]) == ["open", "paid"]
      assert State.values("any") == []
      assert State.values("") == []
      assert State.values(nil) == []
    end

    test "any_of? is true with nothing picked or a picked value" do
      assert State.any_of?("any", "open")
      assert State.any_of?("", nil)
      assert State.any_of?("open,paid", "paid")
      assert State.any_of?("1,2", 2)
      refute State.any_of?("open,paid", "refunded")
      refute State.any_of?("open", nil)
      assert State.any_of?("bug", ["ui", "bug"])
      refute State.any_of?("bug", ["ui"])
    end

    test "put_filters joins what the form sent, defaults a cleared key, keeps the rest" do
      state = State.from_params(%{"status" => "open", "owner" => "pat", "stage" => "won"}, @opts)

      state =
        State.put_filters(
          state,
          %{"status" => ["paid", "refunded"], "stage" => "", "q" => "ignored"},
          ["status", "stage", "owner"],
          @opts
        )

      assert state.filters == %{"status" => "paid,refunded", "stage" => "open", "owner" => "pat"}
      assert state.search == ""
    end

    test "put_filters: a key the form didn't send, or outside keys, stays" do
      state = State.from_params(%{"status" => "open"}, @opts)
      assert State.put_filters(state, %{"owner" => "sam"}, ["status"], @opts) == state
    end

    test "put_filters: a cleared key without a default is dropped" do
      state = %State{filters: %{"tag" => "x"}}
      assert State.put_filters(state, %{"tag" => ""}, [:tag]).filters == %{}
    end

    test "put_search trims, and nil keeps the search" do
      state = State.put_search(%State{}, "  north wind ")
      assert state.search == "north wind"
      assert State.put_search(state, nil).search == "north wind"
      assert State.put_search(state, "").search == ""
    end

    test "chips label each active filter from its options" do
      state = State.from_params(%{"status" => "open,paid", "owner" => "pat"}, @opts)

      assert State.chips(state, ["status", "owner", "stage"], %{
               "status" => [{"Open", "open"}, {"Paid", "paid"}],
               "owner" => %{"pat" => "Pat Lee"},
               "stage" => ["open", "won"]
             }) == [
               {"status", [{"open", "Open"}, {"paid", "Paid"}]},
               {"owner", "Pat Lee"},
               {"stage", "open"}
             ]
    end

    test "chips: a value picked twice counts once" do
      state = State.from_params(%{"status" => "open,open", "owner" => "pat,sam,pat"}, @opts)

      assert State.chips(state, ["status", "owner"], %{"status" => [{"Open", "open"}]}) == [
               {"status", "Open"},
               {"owner", [{"pat", "pat"}, {"sam", "sam"}]}
             ]
    end

    test "remove_value takes one value off, in order" do
      state = %State{filters: %{"status" => "open,paid,overdue"}}

      assert State.remove_value(state, "status", "paid").filters == %{"status" => "open,overdue"}
      assert State.remove_value(state, :status, "open").filters == %{"status" => "paid,overdue"}
    end

    test "remove_value: the last value goes back to the filter's default" do
      state = %State{filters: %{"status" => "open", "owner" => "pat"}}

      assert State.remove_value(state, "status", "open", filters: %{"status" => "any"}).filters ==
               %{"status" => "any", "owner" => "pat"}

      # a real default
      assert State.remove_value(state, "status", "open", filters: %{"status" => "open"}).filters ==
               %{"status" => "open", "owner" => "pat"}

      # no opts: dropped, which the URL reads as the default
      dropped = State.remove_value(state, "status", "open")
      assert dropped.filters == %{"owner" => "pat"}
      assert State.to_params(dropped, @opts) == %{"owner" => "pat"}
      assert State.from_params(State.to_params(dropped, @opts), @opts).filters["status"] == "any"
    end

    test "remove_value: a value the filter doesn't hold changes nothing" do
      state = %State{filters: %{"status" => "open,paid"}}
      assert State.remove_value(state, "status", "refunded") == state
      assert State.remove_value(state, "owner", "pat") == state

      assert State.remove_value(%State{filters: %{"owner" => "any"}}, "owner", "any").filters ==
               %{"owner" => "any"}
    end

    test "remove_value: non-string values and duplicates" do
      assert State.remove_value(%State{filters: %{"id" => "1,2"}}, "id", 2).filters == %{
               "id" => "1"
             }

      assert State.remove_value(%State{filters: %{"id" => "1,1,2"}}, "id", 1).filters == %{
               "id" => "2"
             }
    end

    test "chips: a value without a label shows as itself; no value, no chip" do
      state = State.from_params(%{"status" => "archived"}, @opts)
      assert State.chips(state, [:status, :owner]) == [{"status", "archived"}]
    end
  end

  describe "sorting" do
    test "sort_value is key:dir, or empty for the default order" do
      assert State.sort_value(%State{}) == ""
      assert State.sort_value(%State{sort: "total", dir: :desc}) == "total:desc"
    end

    test "parse_sort keeps the sort for nil or an unknown key, resets it for empty" do
      state = %State{sort: "total", dir: :desc}

      assert State.parse_sort(nil, state, @opts) == state
      assert State.parse_sort("secret:asc", state, @opts) == state
      assert State.parse_sort("", state, @opts) == %State{sort: nil, dir: :asc}
      assert State.parse_sort("number:asc", state, @opts) == %State{sort: "number", dir: :asc}
      assert State.parse_sort("placed:desc", state, @opts) == %State{sort: "placed", dir: :desc}
      assert State.parse_sort("number", state, @opts) == %State{sort: "number", dir: :asc}
    end

    test "toggle_sort: ascending, descending, then the default order" do
      s1 = State.toggle_sort(%State{}, "total")
      assert {s1.sort, s1.dir} == {"total", :asc}
      s2 = State.toggle_sort(s1, "total")
      assert {s2.sort, s2.dir} == {"total", :desc}
      s3 = State.toggle_sort(s2, "total")
      assert {s3.sort, s3.dir} == {nil, :asc}
      s4 = State.toggle_sort(s2, :number)
      assert {s4.sort, s4.dir} == {"number", :asc}
    end
  end

  describe "run/3" do
    @rows [
      %{id: 1, name: "Blue Harbor Inn", status: "paid", total: 120, placed: ~D[2026-10-02]},
      %{id: 2, name: "riverside dental", status: "open", total: nil, placed: ~D[2026-09-30]},
      %{id: 3, name: "Northgate Pharmacy", status: "open", total: 980, placed: nil},
      %{id: 4, name: "Harbor Hardware", status: "refunded", total: 45, placed: ~D[2026-10-11]},
      %{id: 5, name: "Maple Harbor", status: "paid", total: 120, placed: ~D[2025-12-31]}
    ]

    defp spec do
      %{
        search: &"#{&1.name} #{&1.status}",
        filters: %{"status" => &State.any_of?(&2, &1.status)},
        sorts: %{"name" => & &1.name, "total" => & &1.total, "placed" => & &1.placed}
      }
    end

    defp ids(rows), do: Enum.map(rows, & &1.id)

    test "no search, filters or sort: the rows as they are" do
      assert ids(State.run(@rows, %State{}, spec())) == [1, 2, 3, 4, 5]
    end

    test "every word typed must appear, ignoring case" do
      assert ids(State.run(@rows, %State{search: "HARBOR"}, spec())) == [1, 4, 5]
      assert ids(State.run(@rows, %State{search: "harbor paid"}, spec())) == [1, 5]
      assert ids(State.run(@rows, %State{search: "harbor zzz"}, spec())) == []
    end

    test "filters with a value apply; none passes everything" do
      assert ids(State.run(@rows, %State{filters: %{"status" => "open,refunded"}}, spec())) ==
               [2, 3, 4]

      assert ids(State.run(@rows, %State{filters: %{"status" => "any"}}, spec())) ==
               [1, 2, 3, 4, 5]
    end

    test "empty values sort last in both directions; equal rows keep their order" do
      assert ids(State.run(@rows, %State{sort: "total", dir: :asc}, spec())) == [4, 1, 5, 3, 2]
      assert ids(State.run(@rows, %State{sort: "total", dir: :desc}, spec())) == [3, 1, 5, 4, 2]
    end

    test "dates compare by value, not as terms" do
      assert ids(State.run(@rows, %State{sort: "placed", dir: :asc}, spec())) == [5, 2, 1, 4, 3]
      assert ids(State.run(@rows, %State{sort: "placed", dir: :desc}, spec())) == [4, 1, 2, 5, 3]
    end

    test "text sorts ignoring case" do
      assert ids(State.run(@rows, %State{sort: "name", dir: :asc}, spec())) == [1, 4, 5, 3, 2]
    end

    test "datetimes and times compare by value" do
      rows = [
        %{id: 1, at: ~U[2026-10-02 09:00:00Z]},
        %{id: 2, at: ~U[2026-10-02 10:00:00Z]},
        %{id: 3, at: ~U[2025-01-01 23:00:00Z]}
      ]

      assert ids(State.run(rows, %State{sort: "at"}, sorts: [at: & &1.at])) == [3, 1, 2]

      times = [%{id: 1, at: ~T[10:00:00]}, %{id: 2, at: ~T[09:30:00]}]
      assert ids(State.run(times, %State{sort: "at", dir: :desc}, sorts: [at: & &1.at])) == [1, 2]
    end

    test "a sort key without a function leaves the order" do
      assert ids(State.run(@rows, %State{sort: "nope"}, spec())) == [1, 2, 3, 4, 5]
    end
  end

  describe "selection" do
    @visible ~w(a b c d e)

    test "select toggles a row and makes it the anchor" do
      s = State.select(%State{}, "b", false, @visible)
      assert s.selected == MapSet.new(["b"])
      assert s.anchor == "b"
      assert State.selected?(s, "b")

      s = State.select(s, "b", false, @visible)
      assert s.selected == MapSet.new()
      assert s.anchor == "b"
    end

    test "shift ticks the range from the anchor, in the order shown, either way" do
      s = %State{} |> State.select("b", false, @visible) |> State.select("d", true, @visible)
      assert s.selected == MapSet.new(~w(b c d))
      assert s.anchor == "d"

      s = %State{} |> State.select("e", false, @visible) |> State.select("c", true, @visible)
      assert s.selected == MapSet.new(~w(c d e))
    end

    test "shift ticks the range even through ticked rows (it never unticks)" do
      s =
        %State{}
        |> State.select("a", false, @visible)
        |> State.select("c", false, @visible)
        |> State.select("e", true, @visible)

      assert s.selected == MapSet.new(~w(a c d e))
    end

    test "shift without an anchor, or with one no longer shown, toggles" do
      assert State.select(%State{}, "c", true, @visible).selected == MapSet.new(["c"])

      s = %State{anchor: "gone"} |> State.select("c", true, @visible)
      assert s.selected == MapSet.new(["c"])
    end

    test "ids are strings: an integer and its string are the same row" do
      s = State.select(%State{}, 7, false, [6, 7, 8])
      assert s.selected == MapSet.new(["7"])
      assert State.selected?(s, "7") and State.selected?(s, 7)
      s = State.select(s, "8", true, [6, 7, 8])
      assert s.selected == MapSet.new(["7", "8"])
    end

    test "select_all ticks every shown row, or clears them when all are ticked" do
      s = State.select_all(%State{selected: MapSet.new(["a", "zz"])}, @visible)
      assert s.selected == MapSet.new(~w(a b c d e zz))
      assert s.anchor == nil

      s = State.select_all(s, @visible)
      assert s.selected == MapSet.new(["zz"])
    end

    test "select_all with no rows changes nothing" do
      assert State.select_all(%State{}, []).selected == MapSet.new()
    end

    test "keep_visible drops rows no longer shown, and their anchor" do
      s = %State{selected: MapSet.new(~w(a b x)), anchor: "x"}

      assert State.keep_visible(s, ~w(a b c)) == %State{
               selected: MapSet.new(~w(a b)),
               anchor: nil
             }

      s = %State{selected: MapSet.new(~w(a b)), anchor: "b"}
      assert State.keep_visible(s, ~w(b)).anchor == "b"
    end

    test "clear unticks everything" do
      s = %State{selected: MapSet.new(~w(a b)), anchor: "b"}
      assert State.clear(s) == %State{}
    end
  end
end
