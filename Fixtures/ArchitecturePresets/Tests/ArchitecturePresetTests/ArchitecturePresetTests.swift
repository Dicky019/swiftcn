//
//  ArchitecturePresetTests.swift
//  Fixtures/ArchitecturePresets/Tests/ArchitecturePresetTests
//
//  Created by Dicky Darmawan on 03/10/26.
//

import ComposableArchitecture
import MVVMPreset
import NativePreset
import PresetApplication
import PresetDomain
import PresetNavigation
import TCAPreset
import Testing

@Suite("Architecture recipes")
struct ArchitecturePresetTests {
  @Test
  func nativeUseCaseChangesViewFacingValueWithoutViewModel() {
    let result = IncrementScore().execute(Score(value: 4))
    #expect(result.value == 5)
  }

  @Test
  func domainKeepsScoreNonnegative() {
    #expect(Score(value: -7).value == 0)
  }

  @Test @MainActor
  func mvvmOwnsStateAndEmitsStableOutcome() {
    let model = ScoreViewModel()
    model.incrementTapped()
    model.detailsTapped()
    model.incrementTapped()
    #expect(model.score.value == 2)
    #expect(model.outcome == .showDetails(score: 1))
  }

  @Test @MainActor
  func mvvmFlowConsumesOutcomeOnce() {
    let model = ScoreViewModel()
    let flow = ScoreFlow()
    model.detailsTapped()
    flow.handle(model.takeNavigationOutcome())
    flow.handle(model.takeNavigationOutcome())
    #expect(flow.router.path == [.details(score: 0)])
    #expect(model.outcome == nil)
  }

  @Test @MainActor
  func mvvmFlowRejectsInvalidOutcomeBeforeNavigation() {
    let flow = ScoreFlow()
    flow.handle(.showDetails(score: -1))
    #expect(flow.router.path.isEmpty)
  }

  @Test @MainActor
  func tcaReducerOwnsScore() async {
    let store = TestStore(initialState: ScoreFeature.State()) { ScoreFeature() }
    await store.send(.incrementTapped) { $0.score = Score(value: 1) }
  }

  @Test @MainActor
  func tcaNavigationOwnsPushChildStateAndPop() async {
    let store = TestStore(initialState: AppFeature.State()) { AppFeature() }
    await store.send(.showScore) { $0.path.append(.score(ScoreFeature.State())) }
    let id = store.state.path.ids.first!
    await store.send(.path(.element(id: id, action: .score(.incrementTapped)))) {
      $0.path[id: id, case: \.score]?.score = Score(value: 1)
    }
    await store.send(.popToRoot) { $0.path.removeAll() }
  }

  @Test @MainActor
  func tcaNavigationOwnsPresentationChildStateAndDismiss() async {
    let store = TestStore(initialState: AppFeature.State()) { AppFeature() }
    await store.send(.presentScore) { $0.destination = .score(ScoreFeature.State()) }
    await store.send(.destination(.presented(.score(.incrementTapped)))) {
      $0.destination = .score(ScoreFeature.State(score: Score(value: 1)))
    }
    await store.send(.destination(.dismiss)) { $0.destination = nil }
  }
}
