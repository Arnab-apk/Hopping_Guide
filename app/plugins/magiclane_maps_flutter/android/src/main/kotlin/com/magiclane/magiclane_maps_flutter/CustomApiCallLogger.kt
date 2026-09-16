/*
 * SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
 * SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
 *
 * For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
 * For further information use the contact form at https://www.magiclane.com/web/contact.
 */

package com.magiclane.magiclane_maps_flutter

import com.magiclane.sdk.core.ApiCallLogger

class CustomApiCallLogger(
    var logLevel: Int = 0,
    var useSystemLogging: Boolean = true
) : ApiCallLogger() {
    override fun onGetLogLevel(): Int = logLevel
    override fun onUseSystemLogging(): Boolean = useSystemLogging
}
