// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// A task handler is a reference to a task that is currently running or has been scheduled to run.
/// It can be used to cancel the task.
///
/// {@category Common}
abstract class TaskHandler {}

/// @nodoc
///
/// {@category Common}
class TaskHandlerImpl extends TaskHandler {
  TaskHandlerImpl(this._id);
  final dynamic _id;

  dynamic get id => _id;
}
