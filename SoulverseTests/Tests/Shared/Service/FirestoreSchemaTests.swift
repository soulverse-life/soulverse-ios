//
//  FirestoreSchemaTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class FirestoreSchemaTests: XCTestCase {

    // MARK: - FirestoreCollection Constants

    func test_FirestoreCollection_users_equalsExpectedValue() {
        XCTAssertEqual(FirestoreCollection.users, "users")
    }

    func test_FirestoreCollection_moodCheckIns_equalsExpectedValue() {
        XCTAssertEqual(FirestoreCollection.moodCheckIns, "mood_checkins")
    }

    func test_FirestoreCollection_drawings_equalsExpectedValue() {
        XCTAssertEqual(FirestoreCollection.drawings, "drawings")
    }

    // MARK: - StorageFile Raw Values

    func test_StorageFile_image_rawValue() {
        XCTAssertEqual(StorageFile.image.rawValue, "image.png")
    }

    func test_StorageFile_recording_rawValue() {
        XCTAssertEqual(StorageFile.recording.rawValue, "recording.pkd")
    }

    func test_StorageFile_thumbnail_rawValue() {
        XCTAssertEqual(StorageFile.thumbnail.rawValue, "thumbnail.png")
    }

    // MARK: - StorageFile Content Types

    func test_StorageFile_image_contentType_isPNG() {
        XCTAssertEqual(StorageFile.image.contentType, "image/png")
    }

    func test_StorageFile_recording_contentType_isOctetStream() {
        XCTAssertEqual(StorageFile.recording.contentType, "application/octet-stream")
    }

    func test_StorageFile_thumbnail_contentType_isPNG() {
        XCTAssertEqual(StorageFile.thumbnail.contentType, "image/png")
    }

    // MARK: - StorageFile Path Generation

    func test_StorageFile_path_buildsCorrectFormat() {
        let path = StorageFile.image.path(uid: "user123", drawingId: "drawing456")
        XCTAssertEqual(path, "users/user123/drawings/drawing456/image.png")
    }

    func test_StorageFile_recordingPath_buildsCorrectFormat() {
        let path = StorageFile.recording.path(uid: "uid-abc", drawingId: "draw-xyz")
        XCTAssertEqual(path, "users/uid-abc/drawings/draw-xyz/recording.pkd")
    }

    func test_StorageFile_thumbnailPath_buildsCorrectFormat() {
        let path = StorageFile.thumbnail.path(uid: "u1", drawingId: "d2")
        XCTAssertEqual(path, "users/u1/drawings/d2/thumbnail.png")
    }

    func test_StorageFile_path_usesFirestoreCollectionDrawingsConstant() {
        let path = StorageFile.image.path(uid: "u", drawingId: "d")
        XCTAssertTrue(path.contains(FirestoreCollection.drawings))
    }

    // MARK: - StorageFile CaseIterable

    func test_StorageFile_allCases_containsThreeCases() {
        XCTAssertEqual(StorageFile.allCases.count, 3)
    }

    func test_StorageFile_allCases_containsExpectedCases() {
        let cases = Set(StorageFile.allCases)
        XCTAssertTrue(cases.contains(.image))
        XCTAssertTrue(cases.contains(.recording))
        XCTAssertTrue(cases.contains(.thumbnail))
    }
}
